/*
	Description: TheFabricantS1GarmentNFT Contract
   
	TheFabricantS1GarmentNFT NFTs are minted by admins, and can be combined with 
	TheFabricantS1MaterialNFT NFTs to mint TheFabricantS1ItemNFT NFTs.
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract TheFabricantS1GarmentNFT: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// TheFabricantS1GarmentNFT contract Events
	// -----------------------------------------------------------------------
	
	// Emitted when the Garment contract is created
	access(all)
	event ContractInitialized()
	
	// Emitted when a new GarmentData struct is created
	access(all)
	event GarmentDataCreated(garmentDataID: UInt32, designerAddress: Address, metadata:{ String: String})
	
	// Emitted when a Garment is minted
	access(all)
	event GarmentMinted(garmentID: UInt64, garmentDataID: UInt32, serialNumber: UInt32)
	
	access(all)
	event GarmentDataIDRetired(garmentDataID: UInt32)
	
	// Events for Collection-related actions
	//
	// Emitted when a Garment is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when a Garment is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Emitted when a Garment is destroyed
	access(all)
	event GarmentDestroyed(id: UInt64)
	
	// -----------------------------------------------------------------------
	// contract-level fields.	  
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// Contains standard storage and public paths of resources
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// Variable size dictionary of Garment structs
	access(self)
	var garmentDatas:{ UInt32: GarmentData}
	
	// Dictionary with GarmentDataID as key and number of NFTs with GarmentDataID are minted
	access(self)
	var numberMintedPerGarment:{ UInt32: UInt32}
	
	// Dictionary of garmentDataID to  whether they are retired
	access(self)
	var isGarmentDataRetired:{ UInt32: Bool}
	
	// Keeps track of how many unique GarmentData's are created
	access(all)
	var nextGarmentDataID: UInt32
	
	access(all)
	var totalSupply: UInt64
	
	// Royalty struct that each GarmentData will contain
	access(all)
	struct Royalty{ 
		access(all)
		let wallet: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let initialCut: UFix64
		
		access(all)
		let cut: UFix64
		
		/// @param wallet : The wallet to send royalty too
		init(wallet: Capability<&{FungibleToken.Receiver}>, initialCut: UFix64, cut: UFix64){ 
			self.wallet = wallet
			self.initialCut = initialCut
			self.cut = cut
		}
	}
	
	access(all)
	struct GarmentData{ 
		
		// The unique ID for the Garment Data
		access(all)
		let garmentDataID: UInt32
		
		// The flow address of the designer
		access(all)
		let designerAddress: Address
		
		// Other metadata
		access(self)
		let metadata:{ String: String}
		
		// mapping of royalty name to royalty struct
		access(self)
		let royalty:{ String: Royalty}
		
		init(designerAddress: Address, metadata:{ String: String}, royalty:{ String: Royalty}){ 
			self.garmentDataID = TheFabricantS1GarmentNFT.nextGarmentDataID
			self.designerAddress = designerAddress
			self.metadata = metadata
			self.royalty = royalty
			TheFabricantS1GarmentNFT.isGarmentDataRetired[self.garmentDataID] = false
			
			// Increment the ID so that it isn't used again
			TheFabricantS1GarmentNFT.nextGarmentDataID = TheFabricantS1GarmentNFT.nextGarmentDataID + 1
			emit GarmentDataCreated(garmentDataID: self.garmentDataID, designerAddress: designerAddress, metadata: self.metadata)
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun getRoyalty():{ String: Royalty}{ 
			return self.royalty
		}
	}
	
	access(all)
	struct Garment{ 
		
		// The ID of the GarmentData that the Garment references
		access(all)
		let garmentDataID: UInt32
		
		// The N'th NFT with 'GarmentDataID' minted
		access(all)
		let serialNumber: UInt32
		
		init(garmentDataID: UInt32){ 
			self.garmentDataID = garmentDataID
			
			// Increment the ID so that it isn't used again
			TheFabricantS1GarmentNFT.numberMintedPerGarment[garmentDataID] = TheFabricantS1GarmentNFT.numberMintedPerGarment[garmentDataID]! + 1
			self.serialNumber = TheFabricantS1GarmentNFT.numberMintedPerGarment[garmentDataID]!
		}
	}
	
	// The resource that represents the Garment NFTs
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		
		// Global unique Garment ID
		access(all)
		let id: UInt64
		
		// struct of Garment
		access(all)
		let garment: Garment
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(serialNumber: UInt32, garmentDataID: UInt32){ 
			TheFabricantS1GarmentNFT.totalSupply = TheFabricantS1GarmentNFT.totalSupply + 1
			self.id = TheFabricantS1GarmentNFT.totalSupply
			self.garment = Garment(garmentDataID: garmentDataID)
			
			// Emitted when a Garment is minted
			emit GarmentMinted(garmentID: self.id, garmentDataID: garmentDataID, serialNumber: serialNumber)
		}
	}
	
	// Admin is a special authorization resource that
	// allows the owner to perform important functions to modify the 
	// various aspects of the Garment and NFTs
	//
	access(all)
	resource Admin{ 
		access(all)
		fun createGarmentData(designerAddress: Address, metadata:{ String: String}, royalty:{ String: Royalty}): UInt32{ 
			// Create the new GarmentData
			var newGarment = GarmentData(designerAddress: designerAddress, metadata: metadata, royalty: royalty)
			let newID = newGarment.garmentDataID
			
			// Store it in the contract storage
			TheFabricantS1GarmentNFT.garmentDatas[newID] = newGarment
			TheFabricantS1GarmentNFT.numberMintedPerGarment[newID] = 0 as UInt32
			return newID
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
		
		// Mint the new Garment
		access(all)
		fun mintNFT(garmentDataID: UInt32): @NFT{ 
			let numInGarment = TheFabricantS1GarmentNFT.numberMintedPerGarment[garmentDataID] ?? panic("Cannot mint Garment. garmentData not found")
			if TheFabricantS1GarmentNFT.isGarmentDataRetired[garmentDataID]! == nil{ 
				panic("Cannot mint Garment. garmentData not found")
			}
			if TheFabricantS1GarmentNFT.isGarmentDataRetired[garmentDataID]!{ 
				panic("Cannot mint garment. garmentDataID retired")
			}
			let newGarment: @NFT <- create NFT(serialNumber: numInGarment + 1, garmentDataID: garmentDataID)
			return <-newGarment
		}
		
		access(all)
		fun batchMintNFT(garmentDataID: UInt32, quantity: UInt64): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintNFT(garmentDataID: garmentDataID))
				i = i + 1
			}
			return <-newCollection
		}
		
		// Retire garmentData so that it cannot be used to mint anymore
		access(all)
		fun retireGarmentData(garmentDataID: UInt32){ 
			pre{ 
				TheFabricantS1GarmentNFT.isGarmentDataRetired[garmentDataID] != nil:
					"Cannot retire Garment: Garment doesn't exist!"
			}
			if !TheFabricantS1GarmentNFT.isGarmentDataRetired[garmentDataID]!{ 
				TheFabricantS1GarmentNFT.isGarmentDataRetired[garmentDataID] = true
				emit GarmentDataIDRetired(garmentDataID: garmentDataID)
			}
		}
	}
	
	// This is the interface users can cast their Garment Collection as
	// to allow others to deposit into their Collection. It also allows for reading
	// the IDs of Garment in the Collection.
	access(all)
	resource interface GarmentCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowGarment(id: UInt64): &TheFabricantS1GarmentNFT.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Garment reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection is a resource that every user who owns NFTs 
	// will store in their account to manage their NFTS
	//
	access(all)
	resource Collection: GarmentCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// Dictionary of Garment conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an Garment from the Collection and moves it to the caller
		//
		// Parameters: withdrawID: The ID of the NFT 
		// that is to be removed from the Collection
		//
		// returns: @NonFungibleToken.NFT the token that was withdrawn
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Garment does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			
			// Return the withdrawn token
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: ids: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: A collection that contains
		//										the withdrawn Garment
		//
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			// Create a new empty Collection
			var batchCollection <- create Collection()
			
			// Iterate through the ids and withdraw them from the Collection
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			
			// Return the withdrawn tokens
			return <-batchCollection
		}
		
		// deposit takes a Garment and adds it to the Collections dictionary
		//
		// Parameters: token: the NFT to be deposited in the collection
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			// Cast the deposited token as NFT to make sure
			// it is the correct type
			let token <- token as! @TheFabricantS1GarmentNFT.NFT
			
			// Get the token's ID
			let id = token.id
			
			// Add the new token to the dictionary
			let oldToken <- self.ownedNFTs[id] <- token
			
			// Only emit a deposit event if the Collection 
			// is in an account's storage
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			
			// Destroy the empty old token tGarment was "removed"
			destroy oldToken
		}
		
		// batchDeposit takes a Collection object as an argument
		// and deposits each contained NFT into this Collection
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
		
		// getIDs returns an array of the IDs that are in the Collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT Returns a borrowed reference to a Garment in the Collection
		// so tGarment the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		//
		// Note: This only allows the caller to read the ID of the NFT,
		// not an specific data. Please use borrowGarment to 
		// read Garment data.
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(all)
		fun borrowGarment(id: UInt64): &TheFabricantS1GarmentNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &TheFabricantS1GarmentNFT.NFT
			} else{ 
				return nil
			}
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
	
	// If a transaction destroys the Collection object,
	// All the NFTs contained within are also destroyed!
	//
	}
	
	// -----------------------------------------------------------------------
	// Garment contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection creates a new, empty Collection object so that
	// a user can store it in their account storage.
	// Once they have a Collection in their storage, they are able to receive
	// Garment in transactions.
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create TheFabricantS1GarmentNFT.Collection()
	}
	
	// get dictionary of numberMintedPerGarment
	access(all)
	fun getNumberMintedPerGarment():{ UInt32: UInt32}{ 
		return TheFabricantS1GarmentNFT.numberMintedPerGarment
	}
	
	// get how many Garments with garmentDataID are minted 
	access(all)
	fun getGarmentNumberMinted(id: UInt32): UInt32{ 
		let numberMinted = TheFabricantS1GarmentNFT.numberMintedPerGarment[id] ?? panic("garmentDataID not found")
		return numberMinted
	}
	
	// get the garmentData of a specific id
	access(all)
	fun getGarmentData(id: UInt32): GarmentData{ 
		let garmentData = TheFabricantS1GarmentNFT.garmentDatas[id] ?? panic("garmentDataID not found")
		return garmentData
	}
	
	// get all garmentDatas created
	access(all)
	fun getGarmentDatas():{ UInt32: GarmentData}{ 
		return TheFabricantS1GarmentNFT.garmentDatas
	}
	
	access(all)
	fun getGarmentDatasRetired():{ UInt32: Bool}{ 
		return TheFabricantS1GarmentNFT.isGarmentDataRetired
	}
	
	access(all)
	fun getGarmentDataRetired(garmentDataID: UInt32): Bool{ 
		let isGarmentDataRetired = TheFabricantS1GarmentNFT.isGarmentDataRetired[garmentDataID] ?? panic("garmentDataID not found")
		return isGarmentDataRetired
	}
	
	// -----------------------------------------------------------------------
	// initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		// Initialize contract fields
		self.garmentDatas ={} 
		self.numberMintedPerGarment ={} 
		self.nextGarmentDataID = 1
		self.isGarmentDataRetired ={} 
		self.totalSupply = 0
		self.CollectionPublicPath = /public/S1GarmentCollection0021
		self.CollectionStoragePath = /storage/S1GarmentCollection0021
		self.AdminStoragePath = /storage/S1GarmentAdmin0021
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: self.CollectionStoragePath)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{GarmentCollectionPublic}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Put the Minter in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
