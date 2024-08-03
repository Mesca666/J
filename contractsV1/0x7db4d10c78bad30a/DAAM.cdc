// DAAM.cdc
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import DAAM_Profile from 0x509abbf4f85f3d73

import Categories from 0x7db4d10c78bad30a

/************************************************************************/
access(all)
contract DAAM: NonFungibleToken{ 
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?) // Collection Wallet, used to withdraw NFT
	
	
	access(all)
	event Deposit(id: UInt64, to: Address?) // Collection Wallet, used to deposit NFT
	
	
	// Events
	access(all)
	event NewAdmin(admin: Address) // A new Admin has been added. Accepted Invite
	
	
	access(all)
	event NewAgent(agent: Address) // A new Agent has been added. Accepted Invite
	
	
	access(all)
	event NewMinter(minter: Address) // A new Minter has been added. Accepted Invite
	
	
	access(all)
	event NewCreator(creator: Address) // A new Creator has been added. Accepted Invite
	
	
	access(all)
	event AdminInvited(admin: Address) // Admin has been invited
	
	
	access(all)
	event AgentInvited(agent: Address) // Agent has been invited
	
	
	access(all)
	event CreatorInvited(creator: Address) // Creator has been invited
	
	
	access(all)
	event MinterSetup(minter: Address) // Minter has been invited
	
	
	access(all)
	event AddMetadata(creator: Address, mid: UInt64) // Metadata Added
	
	
	access(all)
	event MintedNFT(creator: Address, id: UInt64) // Minted NFT
	
	
	access(all)
	event ChangedCopyright(metadataID: UInt64) // Copyright has been changed to a MID 
	
	
	access(all)
	event ChangeAgentStatus(agent: Address, status: Bool) // Agent Status has been changed by Admin
	
	
	access(all)
	event ChangeCreatorStatus(creator: Address, status: Bool) // Creator Status has been changed by Admin/Agemnt
	
	
	access(all)
	event ChangeMinterStatus(minter: Address, status: Bool) // Minter Status has been changed by Admin
	
	
	access(all)
	event AdminRemoved(admin: Address) // Admin has been removed
	
	
	access(all)
	event AgentRemoved(agent: Address) // Agent has been removed by Admin
	
	
	access(all)
	event CreatorRemoved(creator: Address) // Creator has been removed by Admin
	
	
	access(all)
	event MinterRemoved(minter: Address) // Minter has been removed by Admin
	
	
	access(all)
	event RequestAccepted(mid: UInt64) // Royalty rate has been accepted 
	
	
	access(all)
	event RemovedMetadata(mid: UInt64) // Metadata has been removed by Creator
	
	
	access(all)
	event RemovedAdminInvite(admin: Address) // Admin invitation has been rescinded
	
	
	access(all)
	event CreatorAddAgent(creator: Address, agent: Address)
	
	access(all)
	event BurnNFT(id: UInt64, mid: UInt64, timestamp: UFix64) // Emit when an NFT is burned.
	
	
	access(all)
	event RoyalityRequest(mid: UInt64)
	
	access(all)
	event AgreementReached(mid: UInt64)
	
	// Paths
	access(all)
	let collectionPublicPath: PublicPath // Public path to Collection
	
	
	access(all)
	let collectionStoragePath: StoragePath // Storage path to Collection
	
	
	access(all)
	let metadataPublicPath: PublicPath // Public path that to Metadata Generator: Requires Admin/Agent  or Creator Key
	
	
	access(all)
	let metadataStoragePath: StoragePath // Storage path to Metadata Generator
	
	
	access(all)
	let adminPrivatePath: PrivatePath // Private path to Admin 
	
	
	access(all)
	let adminStoragePath: StoragePath // Storage path to Admin 
	
	
	access(all)
	let minterPrivatePath: PrivatePath // Private path to Minter
	
	
	access(all)
	let minterStoragePath: StoragePath // Storage path to Minter
	
	
	access(all)
	let creatorPrivatePath: PrivatePath // Private path to Creator
	
	
	access(all)
	let creatorStoragePath: StoragePath // Storage path to Creator
	
	
	access(all)
	let requestPrivatePath: PrivatePath // Private path to Request
	
	
	access(all)
	let requestStoragePath: StoragePath // Storage path to Request
	
	
	// Variables
	access(all)
	var totalSupply: UInt64 // the total supply of NFTs, also used as counter for token ID
	
	
	access(contract)
	var remove:{ Address: Address} // Requires 2 Admins to remove an Admin, the Admins are stored here. {Voter : To Remove}
	
	
	access(contract)
	var admins:{ Address: Bool} // {Admin Address : status}  Admin address are stored here
	
	
	access(contract)
	var agents:{ Address: Bool} // {Agents Address : status} Agents address are stored here // preparation for V2
	
	
	access(contract)
	var minters:{ Address: Bool} // {Minters Address : status} Minter address are stored here // preparation for V2
	
	
	access(contract)
	var creators:{ Address: CreatorInfo} // {Creator Address : status} Creator address are stored here
	
	
	access(contract)
	var creatorHistory:{ Address: [UInt64]} // Stores creator history using the MID as a center point of search. {Creator : [MID] }
	
	
	access(contract)
	var agentHistory:{ Address: [Address]} // Stores Agent and their Creators {Agent Address : [Its' Creator Address] }
	
	
	access(contract)
	var metadata:{ UInt64: Bool} // {MID : Approved by Admin } Metadata ID status is stored here
	
	
	access(contract)
	var metadataCap:{ Address: Capability<&MetadataGenerator>} // {MID : Approved by Admin } Metadata ID status is stored here
	
	
	access(contract)
	var request: @{UInt64: Request} // {MID : @Request } Request are stored here by MID
	
	
	access(contract)
	var copyright:{ UInt64: CopyrightStatus} // {NFT.id : CopyrightStatus} Get Copyright Status by Token ID
	
	
	// Variables 
	access(contract)
	var metadataCounterID: UInt64 // The Metadta ID counter for MetadataID.
	
	
	access(contract)
	var newNFTs: [UInt64] // A list of newly minted NFTs. 'New' is defined as 'never sold'. Age is Not a consideration.
	
	
	access(all)
	let agency: MetadataViews.Royalties // DAAM Agency Founder Royaly Addresses
	
	
	access(all)
	let company: MetadataViews.Royalty // DAAM Company Address
	
	
	/***********************************************************************/
	// Copyright enumeration status // Worst(0) to best(4) as UInt8
	access(all)
	enum CopyrightStatus: UInt8{ 
		access(all)
		case FRAUD // 0 as UInt8
		
		
		access(all)
		case CLAIM // 1 as UInt8
		
		
		access(all)
		case UNVERIFIED // 2 as UInt8
		
		
		access(all)
		case VERIFIED // 3 as UInt8
	
	}
	
	/***********************************************************************/
	// Used to make requests for royalty. A resource for Neogoation of royalities.
	// When both parties agree on 'royalty' the Request is considered valid aka isValid() = true and
	// Request manage the royalty rate
	// Accept Default are auto agreements
	access(all)
	resource Request{ 
		access(contract)
		let mid: UInt64 // Metadata ID number is stored
		
		
		access(contract)
		var royalty: MetadataViews.Royalties? // current royalty neogoation.
		
		
		access(contract)
		var agreement: [Bool; 2] // State of agreement [Admin (agrees/disagres),  Creator(agree/disagree)]
		
		
		init(mid: UInt64){ 
			pre{ 
				mid != 0 && mid <= DAAM.metadataCounterID:
					"Illegal Operation: validate"
			}
			self.mid = mid // Get Metadata ID
			
			DAAM.metadata[self.mid] != false // Can set a Request as long as the Metadata has not been Disapproved as oppossed to Aprroved or Not Set.
			
			self.royalty = nil // royalty is initialized
			
			self.agreement = [false, false] // [Agency/Admin, Creator] are both set to Disagree by default
		
		}
		
		access(all)
		fun getMID(): UInt64{ 
			return self.mid
		} // return Metadata ID
		
		
		access(contract)
		fun bargin(isCreator: Bool, mid: UInt64, royalty: MetadataViews.Royalties){ 
			pre{ 
				!self.isValid():
					"Neogoation is already closed. Both parties have already agreed."
			}
			// Elements: 0 = Admin, 1 = Creator
			let receiver = royalty.getRoyalties()[0].receiver!
			let cut = royalty.getRoyalties()[0].cut!
			if isCreator{ 
				self.agreement[0] = self.royaltyMatch(mid, royalty)
				self.agreement[1] = true
			} else{ 
				self.agreement[1] = self.royaltyMatch(mid, royalty)
				self.agreement[0] = true
			}
			self.royalty = royalty
			log("Negotiating")
			if self.isValid(){ 
				log("Agreement Reached")
				emit AgreementReached(mid: mid)
			}
		}
		
		access(self)
		fun royaltyMatch(_ mid: UInt64, _ royalties: MetadataViews.Royalties): Bool{ 
			//if self.royalty!.getRoyalties().length != royalties.getRoyalties().length { return false}
			let royalties_list = self.royalty?.getRoyalties()
			if royalties_list == nil{ 
				return false
			}
			let internal_royalties_list = royalties.getRoyalties()
			log("Royalty MAtch")
			log(royalties_list)
			log(internal_royalties_list)
			var counter = 0
			for royalty in royalties_list!{ 
				if royalty.cut != internal_royalties_list[counter].cut{ 
					return false
				}
				counter = counter + 1
			}
			return true
		}
		
		// Accept Default royalty. Skip Neogations.
		access(contract)
		fun acceptDefault(royalty: MetadataViews.Royalties){ 
			pre{ 
				!self.isValid():
					"Neogoation is already closed. Both parties have already agreed."
				royalty.getRoyalties()[0].cut >= 0.01 || (royalty!).getRoyalties()[0].cut <= 0.3:
					"Defaults are between 1 to 30%."
			}
			self.royalty = royalty // get royalty
			
			self.agreement = [true, true] // set agreement status to Both parties Agreed
		
		}
		
		// If both parties agree (Creator & Admin) return true
		access(all)
		view fun isValid(): Bool{ 
			return self.agreement[0] && self.agreement[1]
		}
	}
	
	/***********************************************************************/
	// Used to create Request Resources. Metadata ID is passed into Request.
	// Request handle Royalities, and Negoatons.
	access(all)
	resource RequestGenerator{ 
		access(self)
		let grantee: Address
		
		init(_ grantee: Address){ 
			self.grantee = grantee
		}
		
		access(all)
		fun createRequest(mid: UInt64, royalty: MetadataViews.Royalties){ 
			pre{ 
				!DAAM.request.containsKey(mid):
					"Already made request for this MID."
				DAAM.isCreator((self.owner!).address) == true || DAAM.isAdmin((self.owner!).address) == true:
					"You do not have access"
			}
			let request <-! (create Request(mid: mid))!
			let old <- DAAM.request.insert(key: mid, <-request) // advice DAAM of request
			
			destroy old
			log("Royality Request: ".concat(mid.toString()))
			emit RoyalityRequest(mid: mid)
		}
		
		// Accept the default Request. No Neogoation is required.
		// Percentages are between 10% - 30%
		access(all)
		fun acceptDefault(mid: UInt64, metadataGen: &MetadataGenerator, royalties: MetadataViews.Royalties){ 
			pre{ 
				mid != 0 && mid <= DAAM.metadataCounterID:
					"Illegal Operation: validate"
				self.grantee == (self.owner!).address:
					"Account: ".concat((self.owner!).address.toString()).concat(" Permission Denied")
				metadataGen.getMIDs().contains(mid):
					"MID: ".concat(mid.toString()).concat(" is Incorrect")
				DAAM.creators.containsKey(self.grantee):
					"Account: ".concat(self.grantee.toString()).concat("You are not a Creator")
				DAAM.isCreator(self.grantee) == true:
					"Account: ".concat(self.grantee.toString()).concat("Your Creator account is Frozen.")
			//percentage >= 0.1 && percentage <= 0.3  : "Percentage must be inbetween 10% to 30%."
			}
			// Getting Agency royalties
			let agency = DAAM.agency.getRoyalties()
			let rate = 0.025
			var royalty_list: [MetadataViews.Royalty] = []
			let creators = (royalties!).getRoyalties()
			var totalCut = 0.0
			var rateCut = 0.0
			for creator in creators{ 
				totalCut = totalCut + creator.cut
				let newCut = creator.cut / (1.0 + rate)
				assert(creator.receiver.borrow() != nil, message: "Illegal Operation 1: AcceptDefault")
				royalty_list.append(MetadataViews.Royalty(receiver: creator.receiver!, cut: newCut, description: "Creator Royalty")) // end append	
				
				rateCut = rateCut + (creator.cut - newCut)
				// Update Creator History
				if !DAAM.creatorHistory.containsKey(creator.receiver.address){ 
					DAAM.creatorHistory[creator.receiver.address] = [mid]
				} else if !(DAAM.creatorHistory[creator.receiver.address]!).contains(mid){ 
					(DAAM.creatorHistory[creator.receiver.address]!).append(mid)
				}
			}
			assert(totalCut >= 0.01 && totalCut <= 0.3, message: "Percentage must be inbetween 10% to 30%.")
			for founder in agency{ 
				assert(founder.receiver.borrow() != nil, message: "Illegal Operation 2: AcceptDefault")
				royalty_list.append(MetadataViews.Royalty(receiver: founder.receiver!, cut: founder.cut * rateCut, description: "Agency Royalty")) // end append 
			
			}
			let request <-! create Request(mid: mid) // get request
			
			let newRoyalties = MetadataViews.Royalties(royalty_list)
			request.acceptDefault(royalty: newRoyalties) // append royalty rate
			
			let old <- DAAM.request.insert(key: mid, <-request) // advice DAAM of request
			
			destroy old // destroy place holder
			
			log("Request Accepted, MID: ".concat(mid.toString()))
			emit RequestAccepted(mid: mid)
		}
	}
	
	/************************************************************************/
	access(all)
	struct MetadataHolder{ // Metadata struct for NFT, will be transfered to the NFT. 
		
		access(all)
		let mid: UInt64
		
		access(all)
		let creatorInfo: CreatorInfo // Creator of NFT
		
		
		access(all)
		let edition: MetadataViews.Edition // series total, number of prints. [counter, total]
		
		
		access(all)
		let category: [Categories.Category]
		
		access(all)
		let description: String // JSON see metadata.json all data ABOUT the NFT is stored here
		
		
		access(all)
		let thumbnail:{ String:{ MetadataViews.File}} // JSON see metadata.json all thumbnails are stored here
		
		
		access(all)
		let misc: String
		
		init(creator: CreatorInfo, mid: UInt64, edition: MetadataViews.Edition, categories: [Categories.Category], description: String, misc: String, thumbnail:{ String:{ MetadataViews.File}}){ 
			pre{ 
				mid != 0 && mid <= DAAM.metadataCounterID:
					"Illegal Operation: validate"
			}
			self.mid = mid
			self.creatorInfo = creator // creator of NFT
			
			self.edition = edition // total prints
			
			self.category = categories
			self.description = description // data,about,misc page
			
			self.thumbnail = thumbnail // thumbnail are stored here
			
			self.misc = misc // Misc.
		
		}
	}
	
	/************************************************************************/
	access(all)
	resource Metadata{ // Metadata struct for NFT, will be transfered to the NFT. 
		
		access(all)
		let mid: UInt64 // Metadata ID number
		
		
		access(all)
		let creatorInfo: CreatorInfo // Creator of NFT
		
		
		access(all)
		let edition: MetadataViews.Edition // series total, number of prints. [counter, total]
		
		
		access(all)
		let category: [Categories.Category]
		
		access(all)
		let description: String // NFT description is stored here
		
		
		access(all)
		let misc: String
		
		access(all)
		let thumbnail:{ String:{ MetadataViews.File}} // JSON see metadata.json all thumbnails are stored here
		
		
		access(all)
		let interact: AnyStruct?
		
		access(all)
		let file:{ String: MetadataViews.Media} // JSON see metadata.json all NFT file formats are stored here
		
		
		init(creator: CreatorInfo?, name: String?, max: UInt64?, categories: [Categories.Category]?, description: String?, misc: String?, thumbnail:{ String:{ MetadataViews.File}}?, interact: AnyStruct?, file:{ String: MetadataViews.Media}?, metadata: &Metadata?){ 
			pre{ 
				DAAM.validInteract(interact):
					"This Interaction is not Authorized"
				max != 0:
					"Max has an incorrect value of 0."
				// Increment Metadata Counter; Make sure Arguments are blank except for Metadata; This also excludes all non consts
				creator == nil && name == nil && categories == nil && description == nil && misc == nil && thumbnail == nil && file == nil && metadata != nil || // or																																								 
																																								 // New Metadata (edition.number = 1) Make sure Arguments are full except for Metadata; This also excludes all non consts
																																								 creator != nil && name != nil && categories != nil && description != nil && misc != nil && thumbnail != nil && file != nil && metadata == nil
			}
			if metadata == nil{ 
				DAAM.metadataCounterID = DAAM.metadataCounterID + 1
				self.mid = DAAM.metadataCounterID // init MID with counter
				
				self.creatorInfo = creator! // creator of NFT
				
				self.edition = MetadataViews.Edition(name: name, number: 1, max: max) // total prints
				
				self.category = categories! // categories 
				
				self.description = description! // data,about,misc page
				
				self.misc = misc! // Misc String
				
				self.thumbnail = thumbnail! // thumbnail are stored here
				
				self.file = file! // NFT data is stored hereere
				
				// below are not Constant or Optional
				self.interact = interact
			} else{ 
				self.mid = (metadata!).mid // init MID with counter
				
				self.creatorInfo = *(metadata!).creatorInfo // creator of NFT
				
				self.edition = MetadataViews.Edition(name: (metadata!).edition.name, number: (metadata!).edition.number + 1, max: (metadata!).edition.max) // Total prints
				
				self.category = (metadata!).category // categories 
				
				self.description = (metadata!).description // data,about,misc page
				
				self.misc = (metadata!).misc // Misc String
				
				self.thumbnail = *(metadata!).thumbnail // thumbnail are stored here
				
				self.file = *(metadata!).file
				// below are not Constant or Optional
				self.interact = (metadata!).interact
				// Error checking; Re-prints do not excede series limit or is Unlimited prints
				if (metadata!).edition.max != nil{ 
					assert((metadata!).edition.number <= (metadata!).edition.max!, message: "Metadata prints are finished.")
				}
			}
		}
		
		access(all)
		fun getHolder(): MetadataHolder{ 
			return MetadataHolder(creator: self.creatorInfo, mid: self.mid, edition: self.edition, categories: self.category, description: self.description, misc: self.misc, thumbnail: self.thumbnail)
		}
		
		access(all)
		fun getDisplay(): MetadataViews.Display{ 
			return MetadataViews.Display(name: self.edition.name!, description: self.description, thumbnail: self.thumbnail[self.thumbnail.keys[0]]!)
		}
	}
	
	/************************************************************************/
	access(all)
	resource interface MetadataGeneratorMint{ 
		// Used to generate a Metadata either new or one with an incremented counter
		// Requires a Minters Key to generate MinterAccess
		access(all)
		fun generateMetadata(minter: @MinterAccess): @Metadata
		
		access(all)
		fun viewMetadata(mid: UInt64): MetadataHolder?
	}
	
	/************************************************************************/
	access(all)
	resource interface MetadataGeneratorPublic{ 
		access(all)
		view fun getMIDs(): [UInt64]
		
		access(all)
		fun viewMetadata(mid: UInt64): MetadataHolder?
		
		access(all)
		fun viewMetadatas(): [MetadataHolder]
		
		access(all)
		fun viewDisplay(mid: UInt64): MetadataViews.Display?
		
		access(all)
		fun viewDisplays(): [MetadataViews.Display]
		
		access(all)
		fun returnMetadata(metadata: @Metadata)
		
		access(all)
		fun getFile(mid: UInt64):{ String: MetadataViews.Media}
	}
	
	/************************************************************************/
	// Verifies each Metadata gets a Metadata ID, and stores the Creators' Metadatas'.
	access(all)
	resource MetadataGenerator: MetadataGeneratorPublic, MetadataGeneratorMint{ 
		// Variables
		access(self)
		var metadata: @{UInt64: Metadata} // {MID : Metadata Resource}
		
		
		access(self)
		var returns: @{UInt64: [Metadata]}
		
		access(self)
		let grantee: Address // original owner
		
		
		init(_ grantee: Address){ 
			self.metadata <-{} // Init Metadata 
			
			self.returns <-{} // Metadata Returns, when a metadata is not sold 
			
			self.grantee = grantee
			DAAM.metadataCap.insert(key: self.grantee, getAccount(self.grantee).capabilities.get<&MetadataGenerator>(DAAM.metadataPublicPath)!)
		}
		
		// addMetadata: Used to add a new Metadata. This sets up the Metadata to be approved by the Admin. Returns the new mid.
		access(all)
		fun addMetadata(name: String, max: UInt64?, categories: [Categories.Category], description: String, misc: String, thumbnail:{ String:{ MetadataViews.File}}, file:{ String: MetadataViews.Media}, interact: AnyStruct?): UInt64{ 
			pre{ 
				self.grantee == (self.owner!).address:
					"Account: ".concat((self.owner!).address.toString()).concat(" Permission Denied")
				DAAM.creators.containsKey(self.grantee):
					"Account: ".concat(self.grantee.toString()).concat("You are not a Creator")
				DAAM.isCreator(self.grantee) == true:
					"Account: ".concat(self.grantee.toString()).concat("Your Creator account is Frozen.")
			}
			let metadata <- create Metadata(creator: DAAM.creators[self.grantee], name: name, max: max, categories: categories, description: description, misc: misc, thumbnail: thumbnail, interact: interact, file: file, metadata: nil) // Create Metadata
			
			let mid = metadata.mid
			let old <- self.metadata[mid] <- metadata // Save Metadata
			
			destroy old
			self.saveMID(mid: mid)
			return mid
		}
		
		// Save Metadata & set copyright setting
		access(contract)
		fun saveMID(mid: UInt64){ 
			DAAM.metadata.insert(key: mid, false) // a metadata ID for Admin approval, currently unapproved (false)
			
			DAAM.copyright.insert(key: mid, CopyrightStatus.UNVERIFIED) // default copyright setting
			
			DAAM.metadata[mid] = true // TODO REMOVE AUTO-APPROVE AFTER DEVELOPMENT
			
			log("Metadata Generatated ID: ".concat(mid.toString()))
			emit AddMetadata(creator: self.grantee, mid: mid)
		}
		
		// RemoveMetadata uses clearMetadata to delete the Metadata.
		// But when deleting a submission the request must also be deleted.
		access(all)
		fun removeMetadata(mid: UInt64){ 
			pre{ 
				mid != 0 && mid <= DAAM.metadataCounterID:
					"Illegal Operation: validate"
				self.grantee == (self.owner!).address:
					"Account: ".concat((self.owner!).address.toString()).concat(" Permission Denied")
				DAAM.creators.containsKey(self.grantee):
					"Account: ".concat(self.grantee.toString()).concat("You are not a Creator")
				DAAM.isCreator(self.grantee) == true:
					"Account: ".concat(self.grantee.toString()).concat("Your Creator account is Frozen.")
				self.metadata[mid] != nil:
					"MetadataID: ".concat(mid.toString()).concat(" does not exist.")
			}
			let old_meta <- self.clearMetadata(mid: mid) // Delete Metadata
			
			destroy old_meta
			let old_request <- DAAM.request.remove(key: mid) // Get Request
			
			destroy old_request // Delete Request
		
		}
		
		// Used to remove Metadata from the Creators metadata dictionary list.
		access(self)
		fun clearMetadata(mid: UInt64): @Metadata{ 
			pre{ 
				mid != 0 && mid <= DAAM.metadataCounterID:
					"Illegal Operation: validate"
			}
			DAAM.metadata.remove(key: mid) // Metadata removed from DAAM. Logging no longer neccessary
			
			DAAM.copyright.remove(key: mid) // remove metadata copyright			
			
			log("Destroyed Metadata")
			emit RemovedMetadata(mid: mid)
			return <-self.metadata.remove(key: mid)! // Metadata removed. Metadata Template has reached its max count (edition)
		
		}
		
		// Remove Metadata as Resource. Metadata + Request = NFT.
		// The Metadata will be destroyed along with a matching Request (same MID) in order to create the NFT
		access(all)
		fun generateMetadata(minter: @MinterAccess): @Metadata{ 
			pre{ 
				self.grantee == (self.owner!).address:
					"Account: ".concat(self.grantee.toString()).concat(" Permission Denied")
				minter.validate(creator: self.grantee):
					"Account: ".concat(self.grantee.toString()).concat(" Minter Access Denied")
				DAAM.creators.containsKey(self.grantee):
					"Account: ".concat(self.grantee.toString()).concat(" You are not a Creator")
				DAAM.isCreator(self.grantee) == true:
					"Account: ".concat(self.grantee.toString()).concat(" Your Creator account is Frozen.")
				self.metadata[minter.mid] != nil:
					"MetadataID: ".concat(minter.mid.toString()).concat(" does not exist.")
				DAAM.metadata[minter.mid] != nil:
					"MetadataID: ".concat(minter.mid.toString()).concat(" This already has been published.")
				DAAM.metadata[minter.mid]!:
					"MetadataID: ".concat(minter.mid.toString()).concat(" Submission has been Disapproved.")
			}
			let mid = minter.mid
			destroy minter
			// Create Metadata with incremented counter/print
			let mRef = &self.metadata[mid] as &Metadata?
			if self.returns[mid] != nil{ 
				if self.returns[mid]?.length! != 0{ 
					let ref = &self.returns[mid] as &[Metadata?]?
					let metadata <- (ref!).remove(at: 0)
					return <-metadata!
				}
			} // Use a return Metadata, instead of increasing the counter print.
			
			// Verify Metadata Counter (print) is not last, if so delete Metadata
			if (mRef!).edition.max != nil{ 
				// if not last, print
				if (mRef!).edition.number < (mRef!).edition.max!{ 
					let new_metadata <- create Metadata(creator: nil, name: nil, max: nil, categories: nil, description: nil, misc: nil, thumbnail: nil, interact: nil, file: nil, metadata: mRef)
					let orig_metadata <- self.metadata[mid] <- new_metadata // Update to new incremented (counter) Metadata
					
					return <-orig_metadata! // Return current Metadata
				
				} else if (mRef!).edition.number == (mRef!).edition.max!{ // Last print 
					
					let orig_metadata <- self.clearMetadata(mid: mid) // Remove metadata template
					
					return <-orig_metadata! // Return current Metadata
				
				} else{ 
					panic("Metadata Prints Finished.")
				}
			}
			// unlimited prints
			let new_metadata <- create Metadata(creator: nil, name: nil, max: nil, categories: nil, description: nil, misc: nil, thumbnail: nil, interact: nil, file: nil, metadata: mRef)
			let orig_metadata <- self.metadata[mid] <- new_metadata // Update to new incremented (counter) Metadata
			
			return <-orig_metadata!
		}
		
		access(all)
		fun returnMetadata(metadata: @Metadata){ 
			pre{ 
				metadata.creatorInfo.creator == self.grantee:
					"Must be returned to an Original Creator"
			}
			if self.returns[metadata.mid] == nil{ // If first return of a Metadata ID 
				
				let old <- self.returns[metadata.mid] <- []
				destroy old
				if self.metadata[metadata.mid] == nil{ 
					self.metadata[metadata.mid] <-! metadata
					return
				}
			}
			let ref = &self.returns[metadata.mid] as &[Metadata]?
			(ref!).append(<-metadata)
		}
		
		access(all)
		view fun getMIDs(): [UInt64]{ 
			return self.metadata.keys
		}
		
		access(all)
		fun viewMetadata(mid: UInt64): MetadataHolder?{ 
			pre{ 
				mid != 0 && mid <= DAAM.metadataCounterID:
					"Illegal Operation: validate"
				self.metadata[mid] != nil:
					"MetadataID: ".concat(mid.toString()).concat(" is not a valid Entry.")
			}
			let mRef = &self.metadata[mid] as &Metadata?
			let data: MetadataHolder? = (mRef!).getHolder() // as MetadataHolder// as &Metadata
			
			return data
		}
		
		access(all)
		fun viewMetadatas(): [MetadataHolder]{ 
			var list: [MetadataHolder] = []
			for m in self.metadata.keys{ 
				let mRef = &self.metadata[m] as &Metadata?
				list.append((mRef!).getHolder())
			}
			return list
		}
		
		access(all)
		fun viewDisplay(mid: UInt64): MetadataViews.Display?{ 
			pre{ 
				mid != 0 && mid <= DAAM.metadataCounterID:
					"Illegal Operation: validate"
				self.metadata[mid] != nil:
					"MetadataID: ".concat(mid.toString()).concat(" is not a valid Entry.")
			}
			let mRef = &self.metadata[mid] as &Metadata?
			return (mRef!).getDisplay()
		}
		
		access(all)
		fun viewDisplays(): [MetadataViews.Display]{ 
			var list: [MetadataViews.Display] = []
			for m in self.metadata.keys{ 
				let mRef = &self.metadata[m] as &Metadata?
				list.append((mRef!).getDisplay())
			}
			return list
		}
		
		access(all)
		fun getFile(mid: UInt64):{ String: MetadataViews.Media}{ 
			pre{ 
				mid != 0 && mid <= DAAM.metadataCounterID:
					"Illegal Operation: validate"
				self.metadata[mid] != nil:
					"MetadataID: ".concat(mid.toString()).concat(" is not a valid Entry.")
			}
			let mRef = &self.metadata[mid] as &Metadata?
			return *(mRef!).file
		}
	}
	
	/************************************************************************/
	access(all)
	resource interface INFT{ 
		access(all)
		let mid: UInt64 // Metadata ID, A unique serialized number
		
		
		access(all)
		let metadata: MetadataHolder // Metadata of NFT
		
		
		access(all)
		let royalty: MetadataViews.Royalties // All royalities percentages
	
	}
	
	/************************************************************************/
	access(all)
	resource NFT: NonFungibleToken.NFT, INFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64 // Token ID, A unique serialized number
		
		
		access(all)
		let mid: UInt64 // Metadata ID, A unique serialized number
		
		
		access(all)
		let metadata: MetadataHolder // Metadata of NFT
		
		
		access(all)
		let royalty: MetadataViews.Royalties // Where all royalities are stored {Address : percentage} Note: 1.0 = 100%
		
		
		access(all)
		let file:{ String: MetadataViews.Media}
		
		init(metadata: @Metadata, request: &Request?){ 
			pre{ 
				metadata.mid == (request!).mid:
					"Metadata and Request have different MIDs. They are not meant for each other."
				((request!).royalty!).getRoyalties().length > 0:
					"There must be at least Royalty Entry."
			}
			DAAM.totalSupply = DAAM.totalSupply + 1 // Increment total supply
			
			self.id = DAAM.totalSupply // Set Token ID with total supply
			
			self.mid = metadata.mid // Set Metadata ID
			
			self.royalty = *(request!).royalty! // Save Request which are the royalities.  
			
			self.metadata = metadata.getHolder() // Save Metadata from Metadata Holder
			
			self.file = metadata.file
			destroy metadata // Destroy no loner needed container Metadata Holder
		
		}
		
		access(all)
		fun getCopyright(): CopyrightStatus{ // Get current NFT Copyright status 
			
			return DAAM.copyright[self.id]! // return copyright status
		
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataHolder>(), Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataHolder>():
					return self.metadata
				default:
					return nil
			}
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	/************************************************************************/
	access(all)
	struct OnChain: MetadataViews.File{ 
		access(self)
		let file: String
		
		init(file: String){ 
			self.file = file
		}
		
		access(all)
		fun uri(): String{ 
			return self.file
		}
	}
	
	/************************************************************************/
	// Wallet Public standards. For Public access only
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun borrowDAAM(id: UInt64): &DAAM.NFT // Get NFT as DAAM.NFT
		
		
		access(all)
		fun getCollection():{ String: NFTCollectionDisplay}
		
		access(all)
		fun depositByAgent(token: @{NonFungibleToken.NFT}, name: String, feature: Bool, permission: &Admin)
	}
	
	/************************************************************************/
	access(all)
	struct interface CollectionDisplay{ 
		access(all)
		var display: MetadataViews.NFTCollectionDisplay
		
		access(all)
		var mid:{ UInt64: Bool} // { MID : Featured }
		
		
		access(all)
		var id:{ UInt64: Bool} // { TokenID : Featured }	
	
	}
	
	/************************************************************************/
	access(all)
	struct NFTCollectionDisplay: CollectionDisplay{ 
		access(all)
		var display: MetadataViews.NFTCollectionDisplay
		
		access(all)
		var mid:{ UInt64: Bool} // { MID : Featured }
		
		
		access(all)
		var id:{ UInt64: Bool} // { TokenID : Featured }
		
		
		init(name: String, description: String, externalURL: MetadataViews.ExternalURL, squareImage: MetadataViews.Media, bannerImage: MetadataViews.Media, socials:{ String: MetadataViews.ExternalURL}){ 
			self.display = MetadataViews.NFTCollectionDisplay(name: name, description: description, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socials)
			self.mid ={} 
			self.id ={} 
		}
		
		access(all)
		fun addMID(creator: &Creator, mid: UInt64, feature: Bool){ 
			pre{ 
				mid != 0 && mid <= DAAM.metadataCounterID:
					"Illegal Operation on MID"
				!self.mid.containsKey(mid):
					"Already is in this Collection."
				DAAM.isCreator(creator.grantee) == true:
					"You are not a Creator or your account is Frozen."
				(DAAM.creatorHistory[creator.grantee]!).contains(mid):
					"This MID does not belong to this Creator."
			}
			post{ 
				self.mid.containsKey(mid):
					"Illegal Operation: addMID: ".concat(mid.toString())
			}
			self.mid.insert(key: mid, feature)
		}
		
		access(all)
		fun addTokenID(id: UInt64, feature: Bool){ 
			pre{ 
				!self.id.containsKey(id):
					"You do not have TokenID: ".concat(id.toString())
			}
			post{ 
				self.id.containsKey(id):
					"Illegal Operation: addTokenID: ".concat(id.toString())
			}
			self.id.insert(key: id, feature)
		}
		
		access(all)
		fun removeMID(creator: &Creator, mid: UInt64){ 
			pre{ 
				mid != 0 && mid <= DAAM.metadataCounterID:
					"Illegal Operation: removeMID (pre)"
				self.mid.containsKey(mid):
					"Already is not in this Collection."
				DAAM.isCreator(creator.grantee) == true:
					"You are not a Creator or your account is Frozen."
				(DAAM.creatorHistory[creator.grantee]!).contains(mid):
					"This MID does not belong to this Creator."
			}
			post{ 
				!self.mid.containsKey(mid):
					"Illegal Operation: removeMID (post) ".concat(mid.toString())
			}
			self.mid.remove(key: mid)
		}
		
		access(all)
		fun removeTokenID(id: UInt64){ // change to &NFT // TODO 
			
			pre{ 
				self.id.containsKey(id):
					"You do not have TokenID: ".concat(id.toString())
			}
			post{ 
				!self.id.containsKey(id):
					"Illegal Operation: removeTokenID: ".concat(id.toString())
			}
			self.id.remove(key: id)
		}
		
		access(all)
		fun adjustFeatureByMID(creator: &Creator, mid: UInt64, feature: Bool){ 
			pre{ 
				self.mid.containsKey(mid):
					"You do not have MID: ".concat(mid.toString())
				DAAM.isCreator(creator.grantee) == true:
					"You are not a Creator or your account is Frozen."
				(DAAM.creatorHistory[creator.grantee]!).contains(mid):
					"This MID does not belong to this Creator."
			}
			self.mid[mid] = feature
		}
		
		access(all)
		fun adjustFeatureByID(id: UInt64, feature: Bool){ 
			pre{ 
				self.id.containsKey(id):
					"You do not have TokenID: ".concat(id.toString())
			}
			self.id[id] = feature
		}
	}
	
	/************************************************************************/
	// Standand Flow Collection Wallet
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic, ViewResolver.ResolverCollection, ViewResolver.Resolver{ 
		// dictionary of NFT conforming tokens. NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}} // Store NFTs via Token ID
		
		
		access(all)
		var collections:{ String: NFTCollectionDisplay}
		
		init(){ 
			self.ownedNFTs <-{} // List of owned NFTs 
			
			self.collections ={} 
		}
		
		access(all)
		fun addCollection(name: String, description: String, externalURL: MetadataViews.ExternalURL, squareImage: MetadataViews.Media, bannerImage: MetadataViews.Media, socials:{ String: MetadataViews.ExternalURL}){ 
			self.collections.insert(key: name, NFTCollectionDisplay(name: name, description: description, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socials))
		}
		
		access(all)
		fun getCollection():{ String: NFTCollectionDisplay}{ 
			return self.collections
		}
		
		access(all)
		fun removeCollection(name: String){ 
			pre{ 
				self.collections.containsKey(name):
					"Collection does not exist."
			}
			self.collections.remove(key: name)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.NFTCollectionDisplay>()]
		/*, Type<MetadataViews.NFTCollectionDisplay>()]*/
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				/*
								return MetadataViews.NFTCollectionData (
									storagePath: DAAM.collectionStoragePath,
									publicPath: DAAM.collectionPublicPath,
									providerPath: DAAM.collectionPrivatePath,
									publicCollection: Type<@DAAM.Collection>(),
									publicLinkedType: Type<&DAAM.Collection{DAAM.CollectionPublic, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, MetadataViews.Resolver}>(),
									providerLinkedType: ?????, // TODO  ???
									createEmptyCollectionFunction: (DAAM.createEmptyCollection() : @DAAM.Collection) // TODO ???
								)*/
				
				case Type<MetadataViews.NFTCollectionDisplay>():
					return self.collections
				default:
					return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			pre{ 
				self.ownedNFTs.containsKey(id):
					"TokenID: ".concat(id.toString().concat(" is not in this collection."))
			}
			let mRef = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return mRef as! &DAAM.NFT
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID)! as! @DAAM.NFT // Get NFT
			
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @DAAM.NFT // Get NFT as DAAM.GFT
			
			let id = token.id // Save Token ID
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token // Store NFT
			
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken // destroy place holder
		
		}
		
		access(all)
		fun depositByAgent(token: @{NonFungibleToken.NFT}, name: String, feature: Bool, permission: &Admin){ 
			pre{ 
				(DAAM.getAgentCreators(agent: permission.grantee)!).contains(self.owner?.address!):
					"Permission Denied."
			}
			let id = token.id
			self.deposit(token: <-token)
			(self.collections[name]!).addTokenID(id: id, feature: feature)
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NonFungibleToken.NFT in the collection.
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Invalid TokenID"
			}
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowDAAM gets a reference to an DAAM.NFT
		access(all)
		fun borrowDAAM(id: UInt64): &DAAM.NFT{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Invalid TokenID"
			}
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let daam = ref as! &DAAM.NFT
			return daam
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
	// Destructor
	}
	
	/************************************************************************/
	// Agent interface. List of all powers belonging to the Agent
	access(all)
	resource interface Agent{ 
		access(all)
		var status: Bool // the current status of the Admin
		
		
		access(all)
		let grantee: Address
		
		access(all)
		fun inviteCreator(_ creator: Address, agentCut: UFix64) // Admin invites a new creator	   
		
		
		access(all)
		fun changeCreatorStatus(creator: Address, status: Bool) // Admin or Agent change Creator status		
		
		
		access(all)
		fun changeCopyright(creator: Address, mid: UInt64, copyright: CopyrightStatus) // Admin or Agenct can change MID copyright status
		
		
		access(all)
		fun changeMetadataStatus(creator: Address, mid: UInt64, status: Bool) // Admin or Agent can change Metadata Status
		
		
		access(all)
		fun removeCreator(creator: Address) // Admin or Agent can remove CAmiRajpal@hotmail.cometadata Status
		
		
		access(all)
		fun newRequestGenerator(): @RequestGenerator // Create Request Generator
		
		
		access(all)
		fun bargin(creator: Address, mid: UInt64, percentage: UFix64)
		
		access(all)
		fun createMetadata(creator: Address, name: String, max: UInt64?, categories: [Categories.Category], description: String, misc: String, thumbnail:{ String:{ MetadataViews.File}}, file:{ String: MetadataViews.Media}, interact: AnyStruct?): @Metadata
	}
	
	/************************************************************************/
	// The Admin Resource deletgates permissions between Founders and Agents
	access(all)
	resource Admin: Agent{ 
		access(all)
		var status: Bool // The current status of the Admin
		
		
		access(all)
		let grantee: Address
		
		init(_ admin: Address){ 
			self.status = true // Default Admin status: True
			
			self.grantee = admin
		}
		
		// Used only when genreating a new Admin. Creates a Resource Generator for Negoiations.
		access(all)
		fun newRequestGenerator(): @RequestGenerator{ 
			pre{ 
				DAAM.admins[(self.owner!).address] == true:
					"Account: ".concat((self.owner!).address.toString()).concat(" Permission Denied. No proper Admin Status")
				self.grantee == (self.owner!).address:
					"Account: ".concat((self.owner!).address.toString()).concat(" Permission Denied")
				self.status:
					"Account: ".concat((self.owner!).address.toString()).concat(" Access has been Frozen.") // status variable may be Depreicated // TODO check 
			
			}
			return <-create RequestGenerator(self.grantee) // return new Request
		
		}
		
		access(all)
		fun inviteAdmin(_ admin: Address){ // Admin invite a new Admin 
			
			pre{ 
				DAAM.admins[(self.owner!).address] == true:
					"Account: ".concat((self.owner!).address.toString()).concat(" Permission Denied")
				self.grantee == (self.owner!).address:
					"Account: ".concat((self.owner!).address.toString()).concat(" Permission Denied")
				self.status:
					"You're no longer a have Access."
				DAAM.creators[admin] == nil:
					"A Admin can not use the same address as an Creator."
				DAAM.agents[admin] == nil:
					"A Admin can not use the same address as an Agent."
				DAAM.admins[admin] == nil:
					"They're already sa DAAM Admin!!!"
				DAAM_Profile.check(admin):
					"You can't be a DAAM Admin without a DAAM Profile! Go make one Fool!!"
			}
			post{ 
				DAAM.admins[admin] == false:
					"Illegal Operaion: inviteAdmin"
			}
			DAAM.admins.insert(key: admin, false) // Admin account is setup but not active untill accepted.
			
			log("Sent Admin Invitation: ".concat(admin.toString()))
			emit AdminInvited(admin: admin)
		}
		
		access(all)
		fun inviteAgent(_ agent: Address){ // Admin ivites new Agent 
			
			pre{ 
				DAAM.admins[(self.owner!).address] == true:
					"Account: ".concat((self.owner!).address.toString()).concat(" Permission Denied")
				self.grantee == (self.owner!).address:
					"Account: ".concat((self.owner!).address.toString()).concat(" Permission Denied")
				self.status:
					"You're no longer a have Access."
				DAAM.admins[agent] == nil:
					"A Agent can not use the same address as an Admin."
				DAAM.creators[agent] == nil:
					"A Agent can not use the same address as an Creator."
				DAAM.agents[agent] == nil:
					"They're already a DAAM Agent!!!"
				DAAM_Profile.check(agent):
					"You can't be a DAAM Admin without a DAAM Profile! Go make one Fool!!"
			}
			post{ 
				DAAM.agents[agent] == false:
					"Illegal Operaion: invite Agent"
				DAAM.admins[agent] == false:
					"Illegal Operaion: invite Agent"
			}
			DAAM.admins.insert(key: agent, false) // Admin account is setup but not active untill accepted.
			
			DAAM.agents.insert(key: agent, false) // Agent account is setup but not active untill accepted.
			
			log("Sent Agent Invitation: ".concat(agent.toString()))
			emit AgentInvited(agent: agent)
		}
		
		access(all)
		fun inviteCreator(_ creator: Address, agentCut: UFix64){ // Admin or Agent invite a new creator, agentCut = nil no agent 
			
			pre{ 
				DAAM.admins[(self.owner!).address] == true:
					"Permission Denied"
				self.grantee == (self.owner!).address:
					"Permission Denied"
				self.status:
					"You're no longer a have Access."
				DAAM.admins[creator] == nil:
					"A Creator can not use the same address as an Admin."
				DAAM.agents[creator] == nil:
					"A Creator can not use the same address as an Agent."
				DAAM.creators[creator] == nil:
					"They're already a DAAM Creator!!!"
				DAAM_Profile.check(creator):
					"You can't be a DAAM Creator without a DAAM Profile! Go make one Fool!!"
			}
			post{ 
				DAAM.isCreator(creator) == false:
					"Illegal Operaion: inviteCreator"
			}
			let agent: Address = DAAM.isAgent((self.owner!).address) == true ? (self.owner!).address : DAAM.company.receiver.address
			let creatorInfo = CreatorInfo(creator: creator, agent: agent, firstSale: agentCut)
			DAAM.creators.insert(key: creator, creatorInfo) // Creator account is setup but not active untill accepted.
			
			log("Sent Creator Invitation: ".concat(creator.toString()))
			emit CreatorInvited(creator: creator)
		}
		
		access(all)
		fun inviteMinter(_ minter: Address){ // Admin invites a new Minter (Key) 
			
			pre{ 
				DAAM.admins[(self.owner!).address] == true:
					"Permission Denied"
				self.grantee == (self.owner!).address:
					"Permission Denied"
				self.status:
					"You're no longer a have Access."
			}
			post{ 
				DAAM.minters[minter] == false:
					"Illegal Operaion: inviteCreator"
			}
			DAAM.minters.insert(key: minter, false) // Minter Key is setup but not active untill accepted.
			
			log("Sent Minter Setup: ".concat(minter.toString()))
			emit MinterSetup(minter: minter)
		}
		
		access(all)
		fun removeAdmin(admin: Address){ // Two Admin to Remove Admin 
			
			pre{ 
				DAAM.admins[(self.owner!).address] == true:
					"Permission Denied"
				self.grantee == (self.owner!).address:
					"Permission Denied"
				self.status:
					"You're no longer a have Access."
			}
			let vote = 5 as Int // TODO change to x
			
			DAAM.remove.insert(key: self.grantee, admin) // Append removal list
			
			if DAAM.remove.length >= vote{ // If votes is 3 or greater 
				
				var counter:{ Address: Int} ={} // {To Remove : Total Votes} 
				
				// Talley Votes
				for a in DAAM.remove.keys{ 
					let remove = DAAM.remove[a]! // get To Remove
					
					// increment counter
					if counter[remove] == nil{ 
						counter.insert(key: remove, 1 as Int)
					} else{ 
						let value = counter[remove]! + 1 as Int
						counter.insert(key: remove, value)
					}
				}
				// Remove all with a vote of 3 or greater
				for c in counter.keys{ 
					if counter[c]! >= vote{ // Does To Remove have enough votes to be removed 
						
						DAAM.remove ={} // Reset DAAM.Remove 
						
						DAAM.admins.remove(key: c) // Remove selected Admin
						
						log("Removed Admin")
						emit AdminRemoved(admin: admin)
					}
				}
			} // end if
		
		}
		
		access(all)
		fun removeAgent(agent: Address){ // Admin removes selected Agent by Address 
			
			pre{ 
				DAAM.admins[(self.owner!).address] == true:
					"Permission Denied"
				self.grantee == (self.owner!).address:
					"Permission Denied"
				self.status:
					"You're no longer a have Access."
				DAAM.agents.containsKey(agent):
					"This is not a Agent Address."
			}
			post{ 
				!DAAM.admins.containsKey(agent):
					"Illegal operation: removeAgent"
				!DAAM.agents.containsKey(agent):
					"Illegal operation: removeAgent"
			} // Unreachable
			
			DAAM.admins.remove(key: agent) // Remove Agent from list
			
			DAAM.agents.remove(key: agent) // Remove Agent from list
			
			log("Removed Agent")
			emit AgentRemoved(agent: agent)
		}
		
		access(all)
		fun removeCreator(creator: Address){ // Admin removes selected Creator by Address 
			
			pre{ 
				DAAM.admins[(self.owner!).address] == true:
					"Permission Denied"
				self.grantee == (self.owner!).address:
					"Permission Denied"
				self.status:
					"You're no longer a have Access."
				DAAM.creators.containsKey(creator):
					"This is not a Creator address."
				DAAM.isAgent((self.owner!).address) == nil || ( // Verify Agent or Admin															   
															   DAAM.agentHistory[(self.owner!).address]!).contains(creator):
					"Access Denied!"
			}
			post{ 
				!DAAM.creators.containsKey(creator):
					"Illegal operation: removeCreator"
			} // Unreachable
			
			DAAM.creators.remove(key: creator) // Remove Creator from list
			
			DAAM.metadataCap.remove(key: creator) // Remove Metadata Capability from list
			
			log("Removed Creator")
			emit CreatorRemoved(creator: creator)
		}
		
		access(all)
		fun removeMinter(minter: Address){ // Admin removes selected Agent by Address 
			
			pre{ 
				DAAM.isAdmin((self.owner!).address) == true:
					"Permission Denied"
				self.grantee == (self.owner!).address:
					"Permission Denied"
				self.status:
					"You're no longer a have Access."
				DAAM.isMinter(minter) != nil:
					"This is not a Minter Address."
			}
			post{ 
				!DAAM.minters.containsKey(minter):
					"Illegal operation: removeAgent"
			} // Unreachable
			
			DAAM.minters.remove(key: minter) // Remove Agent from list
			
			log("Removed Minter")
			emit MinterRemoved(minter: minter)
		}
		
		// Admin can Change Agent status 
		access(all)
		fun changeAgentStatus(agent: Address, status: Bool){ 
			pre{ 
				DAAM.admins[(self.owner!).address] == true:
					"Permission Denied"
				self.grantee == (self.owner!).address:
					"Permission Denied"
				self.status:
					"You're no longer a have Access."
				DAAM.agents.containsKey(agent):
					"Wrong Address. This is not an Agent."
				DAAM.agents[agent] != status:
					"Agent already has this Status."
			}
			post{ 
				DAAM.agents[agent] == status:
					"Illegal Operation: changeCreatorStatus"
			} // Unreachable
			
			DAAM.agents[agent] = status // status changed
			
			log("Agent Status Changed")
			emit ChangeAgentStatus(agent: agent, status: status)
		}
		
		// Admin or Agent can Change Creator status 
		access(all)
		fun changeCreatorStatus(creator: Address, status: Bool){ 
			pre{ 
				DAAM.admins[(self.owner!).address] == true:
					"Permission Denied"
				self.grantee == (self.owner!).address:
					"Permission Denied"
				self.status:
					"You're no longer a have Access."
				DAAM.creators.containsKey(creator):
					"Wrong Address. This is not a Creator."
				DAAM.isCreator(creator) != status:
					"Agent already has this Status."
				DAAM.isAgent((self.owner!).address) == nil || ( // Verify Agent or Admin															   
															   DAAM.agentHistory[(self.owner!).address]!).contains(creator):
					"Access Denied!"
			}
			post{ 
				DAAM.isCreator(creator) == status:
					"Illegal Operation: changeCreatorStatus"
			}
			( // Unreachable			 
			 DAAM.creators[creator]!).setStatus(status) // status changed
			
			log("Creator Status Changed")
			emit ChangeCreatorStatus(creator: creator, status: status)
		}
		
		// Admin can Change Minter status 
		access(all)
		fun changeMinterStatus(minter: Address, status: Bool){ 
			pre{ 
				DAAM.admins[(self.owner!).address] == true:
					"Permission Denied"
				self.grantee == (self.owner!).address:
					"Permission Denied"
				self.status:
					"You're no longer a have Access."
				DAAM.minters.containsKey(minter):
					"Wrong Address. This is not a Minter."
				DAAM.minters[minter] != status:
					"Minter already has this Status."
			}
			post{ 
				DAAM.minters[minter] == status:
					"Illegal Operation: changeCreatorStatus"
			} // Unreachable
			
			DAAM.minters[minter] = status // status changed
			
			log("Minter Status Changed")
			emit ChangeMinterStatus(minter: minter, status: status)
		}
		
		// Admin or Agent can change a Metadata status.
		access(all)
		fun changeMetadataStatus(creator: Address, mid: UInt64, status: Bool){ 
			pre{ 
				mid != 0 && mid <= DAAM.metadataCounterID:
					"Illegal Operation: validate"
				DAAM.admins[(self.owner!).address] == true:
					"Permission Denied"
				self.grantee == (self.owner!).address:
					"Permission Denied"
				self.status:
					"You're no longer a have Access."
				DAAM.copyright.containsKey(mid):
					"This is an Invalid MID"
				DAAM.isAgent((self.owner!).address) == nil || ( // Verify Agent or Admin															   
															   DAAM.agentHistory[(self.owner!).address]!).contains(creator):
					"Access Denied!"
				(DAAM.creatorHistory[creator]!).contains(mid):
					"This Creator does not have this MID"
			}
			DAAM.metadata[mid] = status // change to a new Metadata status
		
		}
		
		// Admin or Agent can change a MIDs copyright status.
		access(all)
		fun changeCopyright(creator: Address, mid: UInt64, copyright: CopyrightStatus){ 
			pre{ 
				mid != 0 && mid <= DAAM.metadataCounterID:
					"Illegal Operation: validate"
				DAAM.admins[(self.owner!).address] == true:
					"Permission Denied"
				self.grantee == (self.owner!).address:
					"Permission Denied"
				self.status:
					"You're no longer a have Access."
				DAAM.copyright.containsKey(mid):
					"This is an Invalid MID"
				DAAM.isAgent((self.owner!).address) == nil || ( // Verify Agent or Admin															   
															   DAAM.agentHistory[(self.owner!).address]!).contains(creator):
					"Access Denied!"
				(DAAM.creatorHistory[creator]!).contains(mid):
					"This Creator does not have this MID"
			}
			post{ 
				DAAM.copyright[mid] == copyright:
					"Illegal Operation: changeCopyright"
			} // Unreachable
			
			DAAM.copyright[mid] = copyright // Change to new copyright
			
			log("MID: ".concat(mid.toString()))
			emit ChangedCopyright(metadataID: mid)
		}
		
		access(all)
		fun addCategory(name: String){ 
			pre{ 
				DAAM.admins[(self.owner!).address] == true:
					"Permission Denied"
				self.grantee == (self.owner!).address:
					"Permission Denied"
				self.status:
					"You're no longer a have Access."
			}
			Categories.addCategory(name: name)
		}
		
		access(all)
		fun removeCategory(name: String){ 
			pre{ 
				DAAM.admins[(self.owner!).address] == true:
					"Permission Denied"
				self.grantee == (self.owner!).address:
					"Permission Denied"
				self.status:
					"You're no longer a have Access."
			}
			Categories.removeCategory(name: name)
		}
		
		access(all)
		fun createMetadata(creator: Address, name: String, max: UInt64?, categories: [Categories.Category], description: String, misc: String, thumbnail:{ String:{ MetadataViews.File}}, file:{ String: MetadataViews.Media}, interact: AnyStruct?): @Metadata{ 
			pre{ 
				DAAM.admins[(self.owner!).address] == true:
					"Permission Denied"
				self.grantee == (self.owner!).address:
					"Permission Denied"
				self.status:
					"You're no longer a have Access."
				(DAAM.getAgentCreators(agent: (self.owner!).address)!).contains(creator):
					"This is not your Creator."
			}
			let metadata <- create Metadata(creator: DAAM.creators[creator], name: name, max: max, categories: categories, description: description, misc: misc, thumbnail: thumbnail, interact: interact, file: file, metadata: nil) // Create Metadata
			
			let mid = metadata.mid
			// copy of MetadataGenerator.saveMID function below
			DAAM.metadata.insert(key: mid, false) // a metadata ID for Admin approval, currently unapproved (false)
			
			DAAM.copyright.insert(key: mid, CopyrightStatus.UNVERIFIED) // default copyright setting
			
			DAAM.metadata[mid] = true // TODO REMOVE AUTO-APPROVE AFTER DEVELOPMENT
			
			log("Metadata Generatated ID: ".concat(mid.toString()))
			emit AddMetadata(creator: self.grantee, mid: mid)
			// end of copy
			return <-metadata
		}
		
		access(all)
		fun bargin(creator: Address, mid: UInt64, percentage: UFix64){ 
			pre{ 
				DAAM.admins[(self.owner!).address] == true:
					"Permission Denied"
				self.grantee == (self.owner!).address:
					"Permission Denied"
				self.status:
					"You're no longer a have Access."
				!DAAM.getRequestValidity(mid: mid):
					"Request already is settled."
				(DAAM.getAgentCreators(agent: (self.owner!).address)!).contains(creator):
					"This is not your Creator."
			}
			let ref = &DAAM.request[mid] as &Request?
			let royalties = [MetadataViews.Royalty(receiver: getAccount(creator).capabilities.get<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())!, cut: percentage, description: "Creator Royalty")]
			let royalty = MetadataViews.Royalties(royalties)
			let request <- DAAM.request.remove(key: mid)!
			request.bargin(isCreator: false, mid: mid, royalty: royalty)
			let old <- DAAM.request[mid] <- request
			destroy old
		}
	}
	
	/************************************************************************/
	access(all)
	struct CreatorInfo{ 
		access(all)
		let creator: Address
		
		access(all)
		let agent: Address
		
		access(all)
		let firstSale: UFix64 // Agent First Sale
		
		
		access(all)
		var status: Bool? // nil = invited, false = frozen, true = active
		
		
		init(creator: Address, agent: Address, firstSale: UFix64){ 
			self.creator = creator
			self.agent = agent
			self.firstSale = firstSale
			self.status = false
		}
		
		access(contract)
		fun setStatus(_ status: Bool?){ 
			self.status = status
		}
	}
	
	/************************************************************************/
	// The Creator Resource (like Admin/Agent) is a permissions Resource. This allows the Creator
	// to Create Metadata which inturn can be made in NFTs after Minting
	access(all)
	resource Creator{ 
		access(contract)
		let grantee: Address
		
		init(_ creator: Address){ 
			self.grantee = creator
		} // init Creators agent(s)
		
		
		// Used to create a Metadata Generator when initalizing Creator Storge
		access(all)
		fun newMetadataGenerator(): @MetadataGenerator{ 
			pre{ 
				self.grantee == (self.owner!).address:
					"Permission Denied"
				DAAM.creators.containsKey(self.grantee):
					"You're not a Creator."
				DAAM.isCreator(self.grantee) == true:
					"Your Creator account is Frozen."
			}
			return <-create MetadataGenerator(self.grantee) // return Metadata Generator
		
		}
		
		// Used to create a Request Generator when initalizing Creator Storge
		access(all)
		fun newRequestGenerator(): @RequestGenerator{ 
			pre{ 
				self.grantee == (self.owner!).address:
					"Permission Denied"
				DAAM.creators.containsKey(self.grantee):
					"You're not a Creator."
				DAAM.isCreator(self.grantee) == true:
					"Your Creator account is Frozen."
			}
			return <-create RequestGenerator(self.grantee) // return Request Generator
		
		}
		
		access(all)
		fun bargin(mid: UInt64, percentage: UFix64){ 
			// Verify is Creator
			pre{ 
				self.grantee == (self.owner!).address:
					"Permission Denied"
				DAAM.creators.containsKey(self.grantee):
					"You're not a Creator."
				DAAM.isCreator(self.grantee) == true:
					"Your Creator account is Frozen."
				!DAAM.getRequestValidity(mid: mid):
					"Request already is settled."
			}
			let ref = &DAAM.request[mid] as &Request?
			let royalties = [MetadataViews.Royalty(receiver: getAccount(self.grantee).capabilities.get<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())!, cut: percentage, description: "Creator Royalty")]
			let royalty = MetadataViews.Royalties(royalties)
			let request <- DAAM.request.remove(key: mid)!
			request.bargin(isCreator: true, mid: mid, royalty: royalty)
			let old <- DAAM.request[mid] <- request
			destroy old
		}
	}
	
	/************************************************************************/
	// mintNFT mints a new NFT and returns it.
	// Note: new is defined by newly Minted. Age is not a consideration.
	access(all)
	resource Minter{ 
		access(self)
		let grantee: Address
		
		init(_ minter: Address){ 
			self.grantee = minter
			DAAM.minters.insert(key: minter, true) // Insert new Minter in minter list.
		
		}
		
		access(all)
		fun mintNFT(metadata: @Metadata): @DAAM.NFT{ 
			pre{ 
				DAAM.isCreator(metadata.creatorInfo.creator) == true:
					"Account: ".concat(metadata.creatorInfo.creator.toString()).concat(" This is not our Creator.")
				DAAM.isMinter(self.grantee) == true:
					"Account: ".concat(self.grantee.toString()).concat(" Your Creator account is Frozen.")
				DAAM.request.containsKey(metadata.mid):
					"Invalid Request for MID: ".concat(metadata.mid.toString())
			}
			var isLast = false
			if metadata.edition.max != nil{ 
				isLast = metadata.edition.number == metadata.edition.max!
			}
			let mid = metadata.mid // Get MID
			
			let nft <- create NFT(metadata: <-metadata, request: &DAAM.request[mid] as &Request?) // Create NFT
			
			// Update Request, if last remove.
			if isLast{ 
				let request <- DAAM.request.remove(key: mid)! // Get Request using MID
				
				destroy request // if last destroy request, Request not needed. Counter has reached limit.
			
			}
			self.newNFT(id: nft.id) // Mark NFT as new
			
			log("Minited NFT: ".concat(nft.id.toString()))
			emit MintedNFT(creator: nft.metadata.creatorInfo.creator, id: nft.id)
			return <-nft // return NFT
		
		}
		
		access(all)
		fun createMinterAccess(mid: UInt64): @MinterAccess{ 
			return <-create MinterAccess(self.grantee, mid: mid)
		}
		
		// Removes token from 'new' list. 'new' is defines as newly Mited. Age is not a consideration.
		access(all)
		fun notNew(tokenID: UInt64){ 
			pre{ 
				self.grantee == (self.owner!).address:
					"Permission Denied"
				DAAM.newNFTs.contains(tokenID):
					"Token ID: ".concat(tokenID.toString()).concat(" is Not New.")
			}
			post{ 
				!DAAM.newNFTs.contains(tokenID):
					"Illegal Operation: notNew"
			} // Unreachable
			
			var counter: UInt64 = 0 as UInt64 // start the conter
			
			for nft in DAAM.newNFTs{ // cycle through 'new' list 
				
				if nft == tokenID{ // if Token ID is found 
					
					DAAM.newNFTs.remove(at: counter) // remove from 'new' list
					
					break
				} else{ 
					counter = counter + 1 // increment counter
				
				}
			} // end for
		
		}
		
		// Add NFT to 'new' list
		access(self)
		fun newNFT(id: UInt64){ 
			pre{ 
				!DAAM.newNFTs.contains(id):
					"Token ID: ".concat(id.toString()).concat(" is already set to New.")
			}
			post{ 
				DAAM.newNFTs.contains(id):
					"Illegal Operation: newNFT"
			}
			DAAM.newNFTs.append(id) // Append 'new' list
		
		}
	}
	
	/************************************************************************/
	access(all)
	resource MinterAccess{ 
		access(all)
		let minter: Address
		
		access(all)
		var mid: UInt64
		
		init(_ minter: Address, mid: UInt64){ 
			self.minter = minter
			self.mid = mid
		}
		
		access(all)
		view fun validate(creator: Address): Bool{ 
			pre{ 
				DAAM.isMinter(self.minter) == true:
					"You access has been denied."
				DAAM.isCreator(creator) == true:
					creator.toString().concat(" is not a Creator or account is Frozen.")
			}
			if DAAM.isAgent(self.minter) == nil{ 
				return true
			}
			if DAAM.isAgent(self.minter) == false{ 
				return false
			}
			if DAAM.isAgent(self.minter) == true{ 
				let valid_mid = (DAAM.getCreatorMIDs(creator: creator)!).contains(self.mid)
				let is_creators_agent = (DAAM.agentHistory[self.minter]!).contains(creator)
				return valid_mid && is_creators_agent
			}
			return false
		}
	}
	
	/************************************************************************/
	// Public DAAM functions
	// answerInvitation Functions:
	// True : invitation is accepted and invitation setting reset
	// False: invitation is declined and invitation setting reset
	// The Admin potential can accept (True) or deny (False)
	access(all)
	fun answerAdminInvite(newAdmin: AuthAccount, submit: Bool): @Admin?{ 
		pre{ 
			self.isAgent(newAdmin.address) == nil:
				"Account: ".concat(newAdmin.address.toString()).concat(" A Admin can not use the same address as an Agent.")
			self.isCreator(newAdmin.address) == nil:
				"Account: ".concat(newAdmin.address.toString()).concat(" A Admin can not use the same address as an Creator.")
			self.isAdmin(newAdmin.address) == false:
				"Account: ".concat(newAdmin.address.toString()).concat(" You got no DAAM Admin invite.")
			DAAM_Profile.check(newAdmin.address):
				"You can't be a DAAM Admin without a DAAM Profile first. Go make a DAAM Profile first."
		}
		let newAdminAddress: Address = newAdmin.address
		if !submit{ 
			DAAM.admins.remove(key: newAdminAddress) // Release Admin
			
			return nil
		} // Refused invitation. Return and end function
		
		// Invitation accepted at this point
		DAAM.admins[newAdminAddress] = submit // Insert new Admin in admins list.
		
		log("Admin: ".concat(newAdminAddress.toString()).concat(" added to DAAM"))
		emit NewAdmin(admin: newAdminAddress)
		return <-create Admin(newAdminAddress) // Accepted and returning Admin Resource
	
	}
	
	// // The Agent potential can accept (True) or deny (False)
	access(all)
	fun answerAgentInvite(newAgent: AuthAccount, submit: Bool): @Admin?{ 
		pre{ 
			self.isAdmin(newAgent.address) == nil:
				"Account: ".concat(newAgent.address.toString()).concat(" An Agent can not use the same address as an Admin.")
			self.isCreator(newAgent.address) == nil:
				"Account: ".concat(newAgent.address.toString()).concat("A Agent can not use the same address as an Creator.")
			self.isAgent(newAgent.address) == false:
				"Account: ".concat(newAgent.address.toString()).concat(" You got no DAAM Agent invite.")
			DAAM_Profile.check(newAgent.address):
				"You can't be a DAAM Agent without a DAAM Profile first. Go make a DAAM Profile first."
		}
		let newAgentAddress: Address = newAgent.address
		if !submit{ // Refused invitation.  
			
			DAAM.admins.remove(key: newAgentAddress) // Remove potential from Agent list
			
			DAAM.agents.remove(key: newAgentAddress) // Remove potential from Agent list
			
			return nil // Return and end function
		
		}
		// Invitation accepted at this point
		DAAM.admins[newAgentAddress] = submit // Add Admin & set Status (True)
		
		DAAM.agents[newAgentAddress] = submit // Add Agent & set Status (True)
		
		DAAM.agentHistory[newAgentAddress] = [] // Setup Agent History
		
		log("Agent: ".concat(newAgentAddress.toString()).concat(" added to DAAM"))
		emit NewAgent(agent: newAgentAddress)
		return <-(create Admin(newAgentAddress))! // Return Admin Resource as {Agent}
	
	}
	
	// // The Creator potential can accept (True) or deny (False)
	access(all)
	fun answerCreatorInvite(newCreator: AuthAccount, submit: Bool): @Creator?{ 
		pre{ 
			self.isAdmin(newCreator.address) == nil:
				"Account: ".concat(newCreator.address.toString()).concat(" A Creator can not use the same address as an Admin.")
			self.isAgent(newCreator.address) == nil:
				"Account: ".concat(newCreator.address.toString()).concat(" A Creator can not use the same address as an Agent.")
			self.isCreator(newCreator.address) == false:
				"Account: ".concat(newCreator.address.toString()).concat(" You got no DAAM Creator invite.")
			DAAM_Profile.check(newCreator.address):
				"You can't be a DAAM Creator without a DAAM Profile first. Go make a DAAM Profile first."
		}
		let newCreatorAddress: Address = newCreator.address
		if !submit{ // Refused invitation. 
			
			DAAM.creators.remove(key: newCreatorAddress) // Remove potential from Agent list
			
			return nil // Return and end function
		
		}
		(		 // Invitation accepted at this point
		 DAAM.creators[newCreatorAddress]!).setStatus(submit) // Add Creator & set Status (True)
		
		let agent = (DAAM.creators[newCreatorAddress]!).agent
		log("Agent: ".concat(agent.toString()))
		// Update agent History with Creator Address
		if DAAM.agentHistory[agent] == nil{ 
			DAAM.agentHistory[agent] = [newCreatorAddress]
		} else if !(DAAM.agentHistory[agent]!).contains(newCreatorAddress){ 
			(DAAM.agentHistory[agent]!).append(newCreatorAddress)
		}
		log("Creator: ".concat(newCreatorAddress.toString()).concat(" added to DAAM"))
		emit NewCreator(creator: newCreatorAddress)
		return <-(create Creator(newCreatorAddress))! // Return Creator Resource
	
	}
	
	access(all)
	fun answerMinterInvite(newMinter: AuthAccount, submit: Bool): @Minter?{ 
		pre{ 
			self.isMinter(newMinter.address) == false:
				"Account: ".concat(newMinter.address.toString()).concat(" You do not have a Minter Invitation")
		}
		let newMinterAddress: Address = newMinter.address
		if !submit{ // Refused invitation.  
			
			DAAM.minters.remove(key: newMinterAddress) // Remove potential from Agent list
			
			return nil // Return and end function
		
		}
		// Invitation accepted at this point
		log("Minter: ".concat(newMinterAddress.toString()))
		emit NewMinter(minter: newMinterAddress)
		return <-create Minter(newMinterAddress) // Return Minter (Key) Resource
	
	}
	
	// Create an new Collection to store NFTs
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		post{ 
			result.getIDs().length == 0:
				"The created collection must be empty!"
		}
		return <-create DAAM.Collection() // Return Collection Resource
	
	}
	
	// Return list of Agents
	access(all)
	fun getAgents():{ Address: [CreatorInfo]}{ 
		var list:{ Address: [CreatorInfo]} ={} 
		for agent in self.agentHistory.keys{ 
			if self.agents[agent] != true{ 
				continue
			}
			var creatorList: [CreatorInfo] = []
			for creator in self.agentHistory[agent]!{ 
				creatorList.append(self.creators[creator]!)
			}
			list.insert(key: agent, creatorList)
		}
		return list
	}
	
	// Return list of Creators
	access(all)
	fun getCreators():{ Address: CreatorInfo}{ 
		let creators = self.creators.keys
		var list = self.creators
		for creator in creators{ 
			if (self.creators[creator]!).status != true{ 
				list.remove(key: creator)
			}
		}
		return list
	}
	
	access(all)
	view fun getAgentCreators(agent: Address): [Address]?{ 
		return self.agentHistory[agent]
	}
	
	access(all)
	view fun getCreatorMIDs(creator: Address): [UInt64]?{ 
		return self.creatorHistory[creator]
	}
	
	// Return Copyright Status. nil = non-existent MID
	access(all)
	fun getCopyright(mid: UInt64): CopyrightStatus?{ 
		pre{ 
			mid != 0 && mid <= DAAM.metadataCounterID:
				"Illegal Operation: validate"
		}
		return self.copyright[mid]
	}
	
	access(all)
	fun getRoyalties(mid: UInt64): MetadataViews.Royalties{ 
		pre{ 
			mid != 0 && mid <= DAAM.metadataCounterID:
				"Illegal Operation: validate"
			DAAM.request.containsKey(mid):
				"Invalid MID"
		}
		let request = &DAAM.request[mid] as &Request?
		let royalty = (request!).royalty!
		return *royalty
	}
	
	access(all)
	view fun getRequestValidity(mid: UInt64): Bool{ 
		pre{ 
			self.request.containsKey(mid)
		}
		return self.request[mid]?.isValid() == true ? true : false
	}
	
	access(all)
	fun getRequestMIDs(): [UInt64]{ 
		return self.request.keys
	}
	
	access(all)
	fun isNFTNew(id: UInt64): Bool{ // Return True if new 
		
		return self.newNFTs.contains(id) // Note: 'New' is defined a newly minted. Age is not a consideration. 
	
	}
	
	access(all)
	view fun isAdmin(_ admin: Address): Bool?{ 
		if self.admins[admin] == nil{ 
			return nil
		}
		return self.agents[admin] == nil ? self.admins[admin]! : nil
	}
	
	access(all)
	view fun isAgent(_ agent: Address): Bool?{ 
		return self.agents[agent]
	}
	
	access(all)
	view fun isMinter(_ minter: Address): Bool?{ 
		return self.minters[minter]
	}
	
	access(all)
	view fun isCreator(_ creator: Address): Bool?{ 
		return DAAM.creators[creator]?.status
	}
	
	access(self)
	view fun validInteract(_ interact: AnyStruct?): Bool{ 
		if interact == nil{ 
			return true
		}
		let type = interact.getType()
		let identifier = type.identifier
		switch identifier{ 
		}
		return false
	}
	
	/************************************************************************/
	// Init DAAM Contract variables
	init(founders:{ Address: UFix64}, company: Address, defaultAdmins: [Address]){ 
		//let founders: {Address:UFix64} = {0x1beecc6fef95b62e: 0.6, 0x0f7025fa05b578e3: 0.4}
		//let defaultAdmins: [Address] = [0x0f7025fa05b578e3, 0x1beecc6fef95b62e]
		//let company: Address = 0x1beecc6fef95b62e
		// Paths
		self.collectionPublicPath = /public/DAAM_Collection
		self.collectionStoragePath = /storage/DAAM_Collection
		self.metadataPublicPath = /public/DAAM_SubmitNFT
		self.metadataStoragePath = /storage/DAAM_SubmitNFT
		self.adminPrivatePath = /private/DAAM_Admin
		self.adminStoragePath = /storage/DAAM_Admin
		self.minterPrivatePath = /private/DAAM_Minter
		self.minterStoragePath = /storage/DAAM_Minter
		self.creatorPrivatePath = /private/DAAM_Creator
		self.creatorStoragePath = /storage/DAAM_Creator
		self.requestPrivatePath = /private/DAAM_Request
		self.requestStoragePath = /storage/DAAM_Request
		// Setup Up Founders
		var royalty_list: [MetadataViews.Royalty] = []
		var totalCut = 0.0
		for founder in founders.keys{ 
			royalty_list.append(MetadataViews.Royalty(receiver: getAccount(founder).capabilities.get<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())!, cut: founders[founder]!, description: "Founder: ".concat(founder.toString()).concat("Percentage: ").concat((founders[founder]!).toString()))) // end royalty_list 
// end append
			
			totalCut = totalCut + founders[founder]!
		}
		//assert(totalCut == 1.0, message: "Shares Must equal 100%. Currently: ".concat(totalCut.toString()))
		self.agency = MetadataViews.Royalties(royalty_list)
		self.company = MetadataViews.Royalty(receiver: getAccount(company).capabilities.get<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())!, cut: 1.0, description: "Comapny Holding") // end royalty_list
		
		// Initialize variables
		self.admins ={} 
		self.remove ={} 
		self.request <-{} 
		self.copyright ={} 
		self.agents ={} 
		self.creators ={} 
		self.minters ={} 
		self.metadata ={} 
		self.newNFTs = []
		self.metadataCap ={} 
		self.agentHistory ={} 
		self.creatorHistory ={} 
		// Counter varibbles
		self.totalSupply = 0 // Initialize the total supply of NFTs
		
		self.metadataCounterID = 0 // Incremental Serial Number for the MetadataGenerator
		
		// Setup Up Default Admins
		for admin in defaultAdmins{ 
			self.admins.insert(key: admin, false)
		}
		emit ContractInitialized()
	}
}
