/*
	Adapted from: Genies.cdc
	Author: Rhea Myers rhea.myers@dapperlabs.com
	Author: Sadie Freeman sadie.freeman@dapperlabs.com
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

/*
	AllDay is structured similarly to Genies and TopShot.
	Unlike TopShot, we use resources for all entities and manage access to their data
	by copying it to structs (this simplifies access control, in particular write access).
	We also encapsulate resource creation for the admin in member functions on the parent type.

	There are 5 levels of entity:
	1. Series
	2. Sets
	3. Plays
	4. Editions
	4. Moment NFT (an NFT)

	An Edition is created with a combination of a Series, Set, and Play
	Moment NFTs are minted out of Editions.

	Note that we cache some information (Series names/ids, counts of entities) rather
	than calculate it each time.
	This is enabled by encapsulation and saves gas for entity lifecycle operations.
 */

// The AllDay NFTs and metadata contract
//
access(all)
contract AllDay: NonFungibleToken{ 
	//------------------------------------------------------------
	// Events
	//------------------------------------------------------------
	
	// Contract Events
	//
	access(all)
	event ContractInitialized()
	
	// NFT Collection Events
	//
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Series Events
	//
	// Emitted when a new series has been created by an admin
	access(all)
	event SeriesCreated(id: UInt64, name: String)
	
	// Emitted when a series is closed by an admin
	access(all)
	event SeriesClosed(id: UInt64)
	
	// Set Events
	//
	// Emitted when a new set has been created by an admin
	access(all)
	event SetCreated(id: UInt64, name: String)
	
	// Play Events
	//
	// Emitted when a new play has been created by an admin
	access(all)
	event PlayCreated(id: UInt64, classification: String, metadata:{ String: String})
	
	// Edition Events
	//
	// Emitted when a new edition has been created by an admin
	access(all)
	event EditionCreated(id: UInt64, seriesID: UInt64, setID: UInt64, playID: UInt64, maxMintSize: UInt64?, tier: String)
	
	// Emitted when an edition is either closed by an admin, or the max amount of moments have been minted
	access(all)
	event EditionClosed(id: UInt64)
	
	// NFT Events
	//
	access(all)
	event MomentNFTMinted(id: UInt64, editionID: UInt64, serialNumber: UInt64)
	
	access(all)
	event MomentNFTBurned(id: UInt64)
	
	//------------------------------------------------------------
	// Named values
	//------------------------------------------------------------
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let MinterPrivatePath: PrivatePath
	
	//------------------------------------------------------------
	// Publicly readable contract state
	//------------------------------------------------------------
	// Entity Counts
	//
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var nextSeriesID: UInt64
	
	access(all)
	var nextSetID: UInt64
	
	access(all)
	var nextPlayID: UInt64
	
	access(all)
	var nextEditionID: UInt64
	
	//------------------------------------------------------------
	// Internal contract state
	//------------------------------------------------------------
	// Metadata Dictionaries
	//
	// This is so we can find Series by their names (via seriesByID)
	access(self)
	let seriesIDByName:{ String: UInt64}
	
	access(self)
	let seriesByID: @{UInt64: Series}
	
	access(self)
	let setIDByName:{ String: UInt64}
	
	access(self)
	let setByID: @{UInt64: Set}
	
	access(self)
	let playByID: @{UInt64: Play}
	
	access(self)
	let editionByID: @{UInt64: Edition}
	
	//------------------------------------------------------------
	// Series
	//------------------------------------------------------------
	// A public struct to access Series data
	//
	access(all)
	struct SeriesData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let active: Bool
		
		// initializer
		//
		view init(id: UInt64){ 
			if let series = &AllDay.seriesByID[id] as &AllDay.Series?{ 
				self.id = series.id
				self.name = series.name
				self.active = series.active
			} else{ 
				panic("series does not exist")
			}
		}
	}
	
	// A top-level Series with a unique ID and name
	//
	access(all)
	resource Series{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		var active: Bool
		
		// Close this series
		//
		access(all)
		fun close(){ 
			pre{ 
				self.active == true:
					"not active"
			}
			self.active = false
			emit SeriesClosed(id: self.id)
		}
		
		// initializer
		//
		init(name: String){ 
			pre{ 
				!AllDay.seriesIDByName.containsKey(name):
					"A Series with that name already exists"
			}
			self.id = AllDay.nextSeriesID
			self.name = name
			self.active = true
			
			// Cache the new series's name => ID
			AllDay.seriesIDByName[name] = self.id
			// Increment for the nextSeriesID
			AllDay.nextSeriesID = self.id + 1 as UInt64
			emit SeriesCreated(id: self.id, name: self.name)
		}
	}
	
	// Get the publicly available data for a Series by id
	//
	access(all)
	fun getSeriesData(id: UInt64): AllDay.SeriesData{ 
		pre{ 
			AllDay.seriesByID[id] != nil:
				"Cannot borrow series, no such id"
		}
		return AllDay.SeriesData(id: id)
	}
	
	// Get the publicly available data for a Series by name
	//
	access(all)
	fun getSeriesDataByName(name: String): AllDay.SeriesData{ 
		pre{ 
			AllDay.seriesIDByName[name] != nil:
				"Cannot borrow series, no such name"
		}
		let id = AllDay.seriesIDByName[name]!
		return AllDay.SeriesData(id: id)
	}
	
	// Get all series names (this will be *long*)
	//
	access(all)
	fun getAllSeriesNames(): [String]{ 
		return AllDay.seriesIDByName.keys
	}
	
	// Get series id for name
	//
	access(all)
	fun getSeriesIDByName(name: String): UInt64?{ 
		return AllDay.seriesIDByName[name]
	}
	
	//------------------------------------------------------------
	// Set
	//------------------------------------------------------------
	// A public struct to access Set data
	//
	access(all)
	struct SetData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		var setPlaysInEditions:{ UInt64: Bool}
		
		// member function to check the setPlaysInEditions to see if this Set/Play combination already exists
		access(all)
		fun setPlayExistsInEdition(playID: UInt64): Bool{ 
			return self.setPlaysInEditions.containsKey(playID)
		}
		
		// initializer
		//
		init(id: UInt64){ 
			if let set = &AllDay.setByID[id] as &AllDay.Set?{ 
				self.id = id
				self.name = set.name
				self.setPlaysInEditions = *set.setPlaysInEditions
			} else{ 
				panic("set does not exist")
			}
		}
	}
	
	// A top level Set with a unique ID and a name
	//
	access(all)
	resource Set{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		// Store a dictionary of all the Plays which are paired with the Set inside Editions
		// This enforces only one Set/Play unique pair can be used for an Edition
		access(all)
		var setPlaysInEditions:{ UInt64: Bool}
		
		// member function to insert a new Play to the setPlaysInEditions dictionary
		access(all)
		fun insertNewPlay(playID: UInt64){ 
			self.setPlaysInEditions[playID] = true
		}
		
		// initializer
		//
		init(name: String){ 
			pre{ 
				!AllDay.setIDByName.containsKey(name):
					"A Set with that name already exists"
			}
			self.id = AllDay.nextSetID
			self.name = name
			self.setPlaysInEditions ={} 
			
			// Cache the new set's name => ID
			AllDay.setIDByName[name] = self.id
			// Increment for the nextSeriesID
			AllDay.nextSetID = self.id + 1 as UInt64
			emit SetCreated(id: self.id, name: self.name)
		}
	}
	
	// Get the publicly available data for a Set
	//
	access(all)
	fun getSetData(id: UInt64): AllDay.SetData{ 
		pre{ 
			AllDay.setByID[id] != nil:
				"Cannot borrow set, no such id"
		}
		return AllDay.SetData(id: id)
	}
	
	// Get the publicly available data for a Set by name
	//
	access(all)
	fun getSetDataByName(name: String): AllDay.SetData{ 
		pre{ 
			AllDay.setIDByName[name] != nil:
				"Cannot borrow set, no such name"
		}
		let id = AllDay.setIDByName[name]!
		return AllDay.SetData(id: id)
	}
	
	// Get all set names (this will be *long*)
	//
	access(all)
	fun getAllSetNames(): [String]{ 
		return AllDay.setIDByName.keys
	}
	
	//------------------------------------------------------------
	// Play
	//------------------------------------------------------------
	// A public struct to access Play data
	//
	access(all)
	struct PlayData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let classification: String
		
		access(all)
		let metadata:{ String: String}
		
		// initializer
		//
		init(id: UInt64){ 
			if let play = &AllDay.playByID[id] as &AllDay.Play?{ 
				self.id = id
				self.classification = play.classification
				self.metadata = *play.metadata
			} else{ 
				panic("play does not exist")
			}
		}
	}
	
	// A top level Play with a unique ID and a classification
	//
	access(all)
	resource Play{ 
		access(all)
		let id: UInt64
		
		access(all)
		let classification: String
		
		// Contents writable if borrowed!
		// This is deliberate, as it allows admins to update the data.
		access(all)
		let metadata:{ String: String}
		
		// initializer
		//
		init(classification: String, metadata:{ String: String}){ 
			self.id = AllDay.nextPlayID
			self.classification = classification
			self.metadata = metadata
			AllDay.nextPlayID = self.id + 1 as UInt64
			emit PlayCreated(id: self.id, classification: self.classification, metadata: self.metadata)
		}
		
		access(contract)
		fun updateDescription(description: String){ 
			self.metadata["description"] = description
		}
		
		access(contract)
		fun updateDynamicMetadata(optTeamName: String?, optPlayerFirstName: String?, optPlayerLastName: String?, optPlayerNumber: String?, optPlayerPosition: String?){ 
			if let teamName = optTeamName{ 
				self.metadata["teamName"] = teamName
			}
			if let playerFirstName = optPlayerFirstName{ 
				self.metadata["playerFirstName"] = playerFirstName
			}
			if let playerLastName = optPlayerLastName{ 
				self.metadata["playerLastName"] = playerLastName
			}
			if let playerNumber = optPlayerNumber{ 
				self.metadata["playerNumber"] = playerNumber
			}
			if let playerPosition = optPlayerPosition{ 
				self.metadata["playerPosition"] = playerPosition
			}
		}
	}
	
	// Get the publicly available data for a Play
	//
	access(all)
	fun getPlayData(id: UInt64): AllDay.PlayData{ 
		pre{ 
			AllDay.playByID[id] != nil:
				"Cannot borrow play, no such id"
		}
		return AllDay.PlayData(id: id)
	}
	
	//------------------------------------------------------------
	// Edition
	//------------------------------------------------------------
	// A public struct to access Edition data
	//
	access(all)
	struct EditionData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let seriesID: UInt64
		
		access(all)
		let setID: UInt64
		
		access(all)
		let playID: UInt64
		
		access(all)
		var maxMintSize: UInt64?
		
		access(all)
		let tier: String
		
		access(all)
		var numMinted: UInt64
		
		// member function to check if max edition size has been reached
		access(all)
		fun maxEditionMintSizeReached(): Bool{ 
			return self.numMinted == self.maxMintSize
		}
		
		// initializer
		//
		view init(id: UInt64){ 
			if let edition = &AllDay.editionByID[id] as &AllDay.Edition?{ 
				self.id = id
				self.seriesID = edition.seriesID
				self.playID = edition.playID
				self.setID = edition.setID
				self.maxMintSize = edition.maxMintSize
				self.tier = edition.tier
				self.numMinted = edition.numMinted
			} else{ 
				panic("edition does not exist")
			}
		}
	}
	
	// A top level Edition that contains a Series, Set, and Play
	//
	access(all)
	resource Edition{ 
		access(all)
		let id: UInt64
		
		access(all)
		let seriesID: UInt64
		
		access(all)
		let setID: UInt64
		
		access(all)
		let playID: UInt64
		
		access(all)
		let tier: String
		
		// Null value indicates that there is unlimited minting potential for the Edition
		access(all)
		var maxMintSize: UInt64?
		
		// Updates each time we mint a new moment for the Edition to keep a running total
		access(all)
		var numMinted: UInt64
		
		// Close this edition so that no more Moment NFTs can be minted in it
		//
		access(contract)
		fun close(){ 
			pre{ 
				self.numMinted != self.maxMintSize:
					"max number of minted moments has already been reached"
			}
			self.maxMintSize = self.numMinted
			emit EditionClosed(id: self.id)
		}
		
		// Mint a Moment NFT in this edition, with the given minting mintingDate.
		// Note that this will panic if the max mint size has already been reached.
		//
		access(all)
		fun mint(serialNumber: UInt64?): @AllDay.NFT{ 
			pre{ 
				self.numMinted != self.maxMintSize:
					"max number of minted moments has been reached"
			}
			var serial = self.numMinted + 1 as UInt64
			if self.maxMintSize == nil{ 
				serial = serialNumber!
			}
			
			// Create the Moment NFT, filled out with our information
			let momentNFT <- create NFT(id: AllDay.totalSupply + 1, editionID: self.id, serialNumber: serial)
			AllDay.totalSupply = AllDay.totalSupply + 1
			// Keep a running total (you'll notice we used this as the serial number for closed editions)
			self.numMinted = self.numMinted + 1 as UInt64
			return <-momentNFT
		}
		
		// initializer
		//
		init(seriesID: UInt64, setID: UInt64, playID: UInt64, maxMintSize: UInt64?, tier: String){ 
			pre{ 
				maxMintSize != 0:
					"max mint size is zero, must either be null or greater than 0"
				AllDay.seriesByID.containsKey(seriesID):
					"seriesID does not exist"
				AllDay.setByID.containsKey(setID):
					"setID does not exist"
				AllDay.playByID.containsKey(playID):
					"playID does not exist"
				SeriesData(id: seriesID).active == true:
					"cannot create an Edition with a closed Series"
				AllDay.getPlayTierExistsInEdition(setID, playID, tier) == false:
					"set play tier combination already exists in an edition"
			}
			self.id = AllDay.nextEditionID
			self.seriesID = seriesID
			self.setID = setID
			self.playID = playID
			
			// If an edition size is not set, it has unlimited minting potential
			if maxMintSize == 0{ 
				self.maxMintSize = nil
			} else{ 
				self.maxMintSize = maxMintSize
			}
			self.tier = tier
			self.numMinted = 0 as UInt64
			AllDay.nextEditionID = AllDay.nextEditionID + 1 as UInt64
			AllDay.setByID[setID]?.insertNewPlay(playID: playID)
			AllDay.insertSetPlayTierMap(setID, playID, tier)
			emit EditionCreated(id: self.id, seriesID: self.seriesID, setID: self.setID, playID: self.playID, maxMintSize: self.maxMintSize, tier: self.tier)
		}
	}
	
	// Get the publicly available data for an Edition
	//
	access(all)
	fun getEditionData(id: UInt64): EditionData{ 
		pre{ 
			AllDay.editionByID[id] != nil:
				"Cannot borrow edition, no such id"
		}
		return AllDay.EditionData(id: id)
	}
	
	//------------------------------------------------------------
	// Internal functions for tracking Editions minted with Set + Play + Tier combinations
	//------------------------------------------------------------
	// Get storage path for SetPlayTierMap
	//
	access(self)
	view fun getSetPlayTierMapStorage(): StoragePath{ 
		return /storage/AllDayAdminSetPlayTierMap
	}
	
	// Get composite key used to read/write SetPlayTierMap
	//
	access(self)
	view fun getSetPlayTierMapKey(_ setID: UInt64, _ playID: UInt64, _ tier: String): String{ 
		return setID.toString().concat("-").concat(playID.toString()).concat("-").concat(tier)
	}
	
	// Check if the given set, play, tier has already been minted in an Edition
	//
	access(self)
	view fun getPlayTierExistsInEdition(_ setID: UInt64, _ playID: UInt64, _ tier: String): Bool{ 
		let setPlayTierMap = AllDay.account.storage.borrow<&{String: Bool}>(from: AllDay.getSetPlayTierMapStorage())!
		return setPlayTierMap.containsKey(AllDay.getSetPlayTierMapKey(setID, playID, tier))
	}
	
	// Insert new entry into SetPlayTierMap
	//
	access(self)
	fun insertSetPlayTierMap(_ setID: UInt64, _ playID: UInt64, _ tier: String){ 
		let setPlayTierMap = AllDay.account.storage.load<{String: Bool}>(from: AllDay.getSetPlayTierMapStorage())!
		setPlayTierMap.insert(key: AllDay.getSetPlayTierMapKey(setID, playID, tier), true)
		AllDay.account.storage.save(setPlayTierMap, to: /storage/AllDayAdminSetPlayTierMap)
	}
	
	//------------------------------------------------------------
	// NFT
	//------------------------------------------------------------
	// A Moment NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let editionID: UInt64
		
		access(all)
		let serialNumber: UInt64
		
		access(all)
		let mintingDate: UFix64
		
		// Destructor
		//
		// NFT initializer
		//
		init(id: UInt64, editionID: UInt64, serialNumber: UInt64){ 
			pre{ 
				AllDay.editionByID[editionID] != nil:
					"no such editionID"
				EditionData(id: editionID).maxEditionMintSizeReached() != true:
					"max edition size already reached"
			}
			self.id = id
			self.editionID = editionID
			self.serialNumber = serialNumber
			self.mintingDate = getCurrentBlock().timestamp
			emit MomentNFTMinted(id: self.id, editionID: self.editionID, serialNumber: self.serialNumber)
		}
		
		// All supported metadata views for the Moment including the Core NFT Views
		//
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Medias>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.getName(), description: self.getDescription(), thumbnail: MetadataViews.HTTPFile(url: self.getImage(imageType: "image", format: "jpeg", width: 256)))
				case Type<MetadataViews.Editions>():
					let editionList: [MetadataViews.Edition] = [self.getEditionInfo()]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://nflallday.com/moments/".concat(self.id.toString()))
				case Type<MetadataViews.Medias>():
					return MetadataViews.Medias([MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "image", format: "jpeg", width: 512)), mediaType: "image/jpeg"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "image-details", format: "jpeg", width: 512)), mediaType: "image/jpeg"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "image-logo", format: "jpeg", width: 512)), mediaType: "image/jpeg"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "image-legal", format: "jpeg", width: 512)), mediaType: "image/jpeg"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "image-player", format: "jpeg", width: 512)), mediaType: "image/jpeg"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "image-scores", format: "jpeg", width: 512)), mediaType: "image/jpeg"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getVideo(videoType: "video")), mediaType: "video/mp4"), MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getVideo(videoType: "video-idle")), mediaType: "video/mp4")])
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: /storage/AllDayNFTCollection, publicPath: /public/AllDayNFTCollection, publicCollection: Type<&AllDay.Collection>(), publicLinkedType: Type<&AllDay.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-AllDay.createEmptyCollection(nftType: Type<@AllDay.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://assets.nflallday.com/flow/catalogue/NFLAD_BANNER.png"), mediaType: "image/png")
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://assets.nflallday.com/flow/catalogue/NFLAD_SQUARE.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "NFL All Day", description: "Officially Licensed Digital Collectibles Featuring the NFL\u{2019}s Best Highlights. Buy, Sell and Collect Your Favorite NFL Moments", externalURL: MetadataViews.ExternalURL("https://nflallday.com/"), squareImage: squareImage, bannerImage: bannerImage, socials:{ "instagram": MetadataViews.ExternalURL("https://www.instagram.com/nflallday/"), "twitter": MetadataViews.ExternalURL("https://twitter.com/NFLAllDay"), "discord": MetadataViews.ExternalURL("https://discord.com/invite/5K6qyTzj2k")})
				case Type<MetadataViews.Royalties>():
					let royaltyReceiver: Capability<&{FungibleToken.Receiver}> = getAccount(0xe4cf4bdc1751c65d).capabilities.get<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())!
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: royaltyReceiver, cut: 0.05, description: "NFL All Day marketplace royalty")])
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.serialNumber)
				case Type<MetadataViews.Traits>():
					let excludedNames: [String] = []
					let fullDictionary = self.getTraits()
					return MetadataViews.dictToTraits(dict: fullDictionary, excludedNames: excludedNames)
			}
			return nil
		}
		
		access(all)
		fun getName(): String{ 
			let edition: EditionData = AllDay.getEditionData(id: self.editionID)
			let play: PlayData = AllDay.getPlayData(id: edition.playID)
			let firstName: String = play.metadata["playerFirstName"] ?? ""
			let lastName: String = play.metadata["playerLastName"] ?? ""
			let playType: String = play.metadata["playType"] ?? ""
			return firstName.concat(" ").concat(lastName).concat(" ").concat(playType)
		}
		
		access(all)
		fun getDescription(): String{ 
			let edition: EditionData = AllDay.getEditionData(id: self.editionID)
			let play: PlayData = AllDay.getPlayData(id: edition.playID)
			let description: String = play.metadata["description"] ?? ""
			if description != ""{ 
				return description
			}
			let series: SeriesData = AllDay.getSeriesData(id: edition.seriesID)
			let set: SetData = AllDay.getSetData(id: edition.setID)
			return series.name.concat(" ").concat(set.name).concat(" moment with serial number ").concat(self.serialNumber.toString())
		}
		
		access(all)
		fun assetPath(): String{ 
			return "https://media.nflallday.com/editions/".concat(self.editionID.toString()).concat("/media/")
		}
		
		access(all)
		fun getImage(imageType: String, format: String, width: Int): String{ 
			return self.assetPath().concat(imageType).concat("?format=").concat(format).concat("&width=").concat(width.toString())
		}
		
		access(all)
		fun getVideo(videoType: String): String{ 
			return self.assetPath().concat(videoType)
		}
		
		access(all)
		fun getMomentURL(): String{ 
			return "https://nflallday.com/moments/".concat(self.id.toString())
		}
		
		access(all)
		fun getEditionInfo(): MetadataViews.Edition{ 
			let edition: EditionData = AllDay.getEditionData(id: self.editionID)
			let set: SetData = AllDay.getSetData(id: edition.setID)
			let name: String = set.name.concat(": #").concat(edition.playID.toString())
			return MetadataViews.Edition(name: name, number: UInt64(self.serialNumber), max: edition.maxMintSize ?? nil)
		}
		
		access(all)
		fun getTraits():{ String: AnyStruct}{ 
			let edition: EditionData = AllDay.getEditionData(id: self.editionID)
			let play: PlayData = AllDay.getPlayData(id: edition.playID)
			let series: SeriesData = AllDay.getSeriesData(id: edition.seriesID)
			let set: SetData = AllDay.getSetData(id: edition.setID)
			let traitDictionary:{ String: AnyStruct} ={ "editionTier": edition.tier, "seriesName": series.name, "setName": set.name, "serialNumber": self.serialNumber}
			for name in play.metadata.keys{ 
				let value = play.metadata[name] ?? ""
				if value != ""{ 
					traitDictionary.insert(key: name, value)
				}
			}
			return traitDictionary
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	//------------------------------------------------------------
	// Collection
	//------------------------------------------------------------
	// A public collection interface that allows Moment NFTs to be borrowed
	//
	access(all)
	resource interface MomentNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowMomentNFT(id: UInt64): &AllDay.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Moment NFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// An NFT Collection
	//
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, MomentNFTCollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an UInt64 ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @AllDay.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// batchDeposit takes a Collection object as an argument
		// and deposits each contained NFT into this Collection
		//
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			// Get an array of the IDs to be deposited
			let keys = tokens.getIDs()
			
			// Iterate through the keys in the collection and deposit each one
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			
			// Destroy the empty Collection
			destroy tokens
		}
		
		// getIDs returns an array of the IDs that are in the collection
		//
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Cannot borrow NFT, no such id"
			}
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowMomentNFT gets a reference to an NFT in the collection
		//
		access(all)
		fun borrowMomentNFT(id: UInt64): &AllDay.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				if let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?{ 
					return ref! as! &AllDay.NFT
				}
				return nil
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let allDayNFT = nft as! &AllDay.NFT
			return allDayNFT as &{ViewResolver.Resolver}
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// Collection destructor
		//
		// Collection initializer
		//
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	//------------------------------------------------------------
	// Admin
	//------------------------------------------------------------
	// An interface containing the Admin function that allows minting NFTs
	//
	access(all)
	resource interface NFTMinter{ 
		// Mint a single NFT
		// The Edition for the given ID must already exist
		//
		access(all)
		fun mintNFT(editionID: UInt64, serialNumber: UInt64?): @AllDay.NFT
	}
	
	// A resource that allows managing metadata and minting NFTs
	//
	access(all)
	resource Admin: NFTMinter{ 
		// Borrow a Series
		//
		access(all)
		fun borrowSeries(id: UInt64): &AllDay.Series{ 
			pre{ 
				AllDay.seriesByID[id] != nil:
					"Cannot borrow series, no such id"
			}
			return (&AllDay.seriesByID[id] as &AllDay.Series?)!
		}
		
		// Borrow a Set
		//
		access(all)
		fun borrowSet(id: UInt64): &AllDay.Set{ 
			pre{ 
				AllDay.setByID[id] != nil:
					"Cannot borrow Set, no such id"
			}
			return (&AllDay.setByID[id] as &AllDay.Set?)!
		}
		
		// Borrow a Play
		//
		access(all)
		fun borrowPlay(id: UInt64): &AllDay.Play{ 
			pre{ 
				AllDay.playByID[id] != nil:
					"Cannot borrow Play, no such id"
			}
			return (&AllDay.playByID[id] as &AllDay.Play?)!
		}
		
		// Borrow an Edition
		//
		access(all)
		fun borrowEdition(id: UInt64): &AllDay.Edition{ 
			pre{ 
				AllDay.editionByID[id] != nil:
					"Cannot borrow edition, no such id"
			}
			return (&AllDay.editionByID[id] as &AllDay.Edition?)!
		}
		
		// Create a Series
		//
		access(all)
		fun createSeries(name: String): UInt64{ 
			// Create and store the new series
			let series <- create AllDay.Series(name: name)
			let seriesID = series.id
			AllDay.seriesByID[series.id] <-! series
			
			// Return the new ID for convenience
			return seriesID
		}
		
		// Close a Series
		//
		access(all)
		fun closeSeries(id: UInt64): UInt64{ 
			if let series = &AllDay.seriesByID[id] as &AllDay.Series?{ 
				series.close()
				return series.id
			}
			panic("series does not exist")
		}
		
		// Create a Set
		//
		access(all)
		fun createSet(name: String): UInt64{ 
			// Create and store the new set
			let set <- create AllDay.Set(name: name)
			let setID = set.id
			AllDay.setByID[set.id] <-! set
			
			// Return the new ID for convenience
			return setID
		}
		
		// Create a Play
		//
		access(all)
		fun createPlay(classification: String, metadata:{ String: String}): UInt64{ 
			// Create and store the new play
			let play <- create AllDay.Play(classification: classification, metadata: metadata)
			let playID = play.id
			AllDay.playByID[play.id] <-! play
			
			// Return the new ID for convenience
			return playID
		}
		
		// Update a play's description metadata
		//
		access(all)
		fun updatePlayDescription(playID: UInt64, description: String): Bool{ 
			if let play = &AllDay.playByID[playID] as &AllDay.Play?{ 
				play.updateDescription(description: description)
			} else{ 
				panic("play does not exist")
			}
			return true
		}
		
		// Update a dynamic moment/play's metadata
		//
		access(all)
		fun updateDynamicMetadata(playID: UInt64, optTeamName: String?, optPlayerFirstName: String?, optPlayerLastName: String?, optPlayerNumber: String?, optPlayerPosition: String?): Bool{ 
			if let play = &AllDay.playByID[playID] as &AllDay.Play?{ 
				play.updateDynamicMetadata(optTeamName: optTeamName, optPlayerFirstName: optPlayerFirstName, optPlayerLastName: optPlayerLastName, optPlayerNumber: optPlayerNumber, optPlayerPosition: optPlayerPosition)
			} else{ 
				panic("play does not exist")
			}
			return true
		}
		
		// Create an Edition
		//
		access(all)
		fun createEdition(seriesID: UInt64, setID: UInt64, playID: UInt64, maxMintSize: UInt64?, tier: String): UInt64{ 
			let edition <- create Edition(seriesID: seriesID, setID: setID, playID: playID, maxMintSize: maxMintSize, tier: tier)
			let editionID = edition.id
			AllDay.editionByID[edition.id] <-! edition
			return editionID
		}
		
		// Close an Edition
		//
		access(all)
		fun closeEdition(id: UInt64): UInt64{ 
			if let edition = &AllDay.editionByID[id] as &AllDay.Edition?{ 
				edition.close()
				return edition.id
			}
			panic("edition does not exist")
		}
		
		// Mint a single NFT
		// The Edition for the given ID must already exist
		//
		access(all)
		fun mintNFT(editionID: UInt64, serialNumber: UInt64?): @AllDay.NFT{ 
			pre{ 
				// Make sure the edition we are creating this NFT in exists
				AllDay.editionByID.containsKey(editionID):
					"No such EditionID"
			}
			return <-self.borrowEdition(id: editionID).mint(serialNumber: serialNumber)
		}
	}
	
	//------------------------------------------------------------
	// Contract lifecycle
	//------------------------------------------------------------
	// AllDay contract initializer
	//
	init(){ 
		// Set the named paths
		self.CollectionStoragePath = /storage/AllDayNFTCollection
		self.CollectionPublicPath = /public/AllDayNFTCollection
		self.AdminStoragePath = /storage/AllDayAdmin
		self.MinterPrivatePath = /private/AllDayMinter
		
		// Initialize the entity counts
		self.totalSupply = 0
		self.nextSeriesID = 1
		self.nextSetID = 1
		self.nextPlayID = 1
		self.nextEditionID = 1
		
		// Initialize the metadata lookup dictionaries
		self.seriesByID <-{} 
		self.seriesIDByName ={} 
		self.setIDByName ={} 
		self.setByID <-{} 
		self.playByID <-{} 
		self.editionByID <-{} 
		
		// Create an Admin resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		// Link capabilites to the admin constrained to the Minter
		// and Metadata interfaces
		var capability_1 = self.account.capabilities.storage.issue<&AllDay.Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.MinterPrivatePath)
		
		//Initialize map to keep track of set+play+tier(edition) combinations that have been minted
		let setPlayTierMap:{ String: Bool} ={} 
		self.account.storage.save(setPlayTierMap, to: AllDay.getSetPlayTierMapStorage())
		
		// Let the world know we are here
		emit ContractInitialized()
	}
}
