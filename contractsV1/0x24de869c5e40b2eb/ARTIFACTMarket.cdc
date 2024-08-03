// SPDX-License-Identifier: Unlicense
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import ARTIFACT, ARTIFACTPack, ARTIFACTAdmin, Interfaces from 0x24de869c5e40b2eb

access(all)
contract ARTIFACTMarket{ 
	
	// -----------------------------------------------------------------------
	// ARTIFACTMarket contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	
	// The next listing ID that is used to create Listing. 
	// Every time a Listing is created, nextListingID is assigned 
	// to the new Listing's ID and then is incremented by 1.
	access(all)
	var nextListingID: UInt64
	
	/// Path where the `SaleCollection` is stored
	access(all)
	let marketStoragePath: StoragePath
	
	/// Path where the public capability for the `SaleCollection` is
	access(all)
	let marketPublicPath: PublicPath
	
	/// Path where the `MarketManager` is stored
	access(all)
	let managerPath: StoragePath
	
	/// Event used on Listing is created 
	access(all)
	event ARTIFACTMarketListed(
		listingID: UInt64,
		price: UFix64,
		saleCuts:{ 
			Address: UFix64
		},
		seller: Address?,
		databaseID: String,
		nftID: UInt64?,
		nftTemplateID: UInt64?,
		packTemplateID: UInt64?
	)
	
	/// Event used on Listing is purchased 
	access(all)
	event ARTIFACTMarketPurchased(
		listingID: UInt64,
		packID: UInt64,
		owner: Address?,
		databaseID: String
	)
	
	/// Event used on Listing is removed 
	access(all)
	event ARTIFACTMarketListingRemoved(listingID: UInt64, owner: Address?)
	
	// -----------------------------------------------------------------------
	// ARTIFACTMarket contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// ----------------------------------------------------------------------- 
	// Listing is a Struct that holds all informations about 
	// the NFT put up to sell
	//
	access(all)
	struct Listing{ 
		access(all)
		let ID: UInt64
		
		// The ID of the NFT
		access(all)
		let nftID: UInt64?
		
		// The ID of the NFT template
		access(all)
		let nftTemplateID: UInt64?
		
		// The ID of the Pack NFT template
		access(all)
		let packTemplateID: UInt64?
		
		// The Type of the FungibleToken that payments must be made in.
		access(all)
		let salePaymentVaultType: Type
		
		// The amount that must be paid in the specified FungibleToken.
		access(all)
		let salePrice: UFix64
		
		// This specifies the division of payment between recipients.
		access(account)
		let saleCuts: [SaleCut]
		
		access(all)
		let sellerCapability: Capability<&FUSD.Vault>
		
		// The whitelist used on pre-sale function
		access(account)
		let whitelist: [Address]
		
		// The field to check if is pre-sale
		access(all)
		var isPreSale: Bool
		
		// The field save buyer
		access(account)
		let buyers:{ Address: UInt64}
		
		// The field with max limit per buyer
		access(account)
		let preSaleBuyerMaxLimit:{ Address: UInt64}
		
		// initializer
		//
		init(
			ID: UInt64,
			nftID: UInt64?,
			nftTemplateID: UInt64?,
			packTemplateID: UInt64?,
			salePrice: UFix64,
			saleCuts: [
				SaleCut
			],
			salePaymentVaultType: Type,
			sellerCapability: Capability<&FUSD.Vault>,
			whitelist: [
				Address
			],
			isPreSale: Bool,
			preSaleBuyerMaxLimit:{ 
				Address: UInt64
			}
		){ 
			pre{ 
				salePrice > 0.0:
					"Listing must have non-zero price"
				sellerCapability.borrow() != nil:
					"Sellers's Receiver Capability is invalid!"
				ARTIFACTMarket.totalSaleCuts(saleCuts: saleCuts) < 100.0:
					"SaleCuts can't be greater or equal a 100"
			}
			self.ID = ID
			self.nftID = nftID
			self.nftTemplateID = nftTemplateID
			self.packTemplateID = packTemplateID
			self.saleCuts = saleCuts
			self.salePrice = salePrice
			self.salePaymentVaultType = salePaymentVaultType
			self.sellerCapability = sellerCapability
			self.whitelist = whitelist
			self.isPreSale = isPreSale
			self.buyers ={} 
			self.preSaleBuyerMaxLimit = preSaleBuyerMaxLimit
		}
		
		access(all)
		fun changePreSaleStatus(isPreSale: Bool){ 
			self.isPreSale = isPreSale
		}
		
		access(all)
		fun increaseBuyers(userAddress: Address, quantity: UInt64){ 
			if self.buyers[userAddress] == nil{ 
				self.buyers[userAddress] = 0
			}
			self.buyers[userAddress] = self.buyers[userAddress]! + quantity
		}
	}
	
	// SaleCut
	// A struct representing a recipient that must be sent a certain amount
	// of the payment when a token is sold.
	//
	access(all)
	struct SaleCut{ 
		// The receiver for the payment.
		// Note that we do not store an address to find the Vault that this represents,
		// as the link or resource that we fetch in this way may be manipulated,
		// so to find the address that a cut goes to you must get this struct and then
		// call receiver.borrow()!.owner.address on it.
		// This can be done efficiently in a script.
		access(all)
		let receiver: Capability<&FUSD.Vault>
		
		// The percentage of the payment that will be paid to the receiver.
		access(all)
		let percentage: UFix64
		
		// initializer
		//
		init(receiver: Capability<&FUSD.Vault>, percentage: UFix64){ 
			self.receiver = receiver
			self.percentage = percentage
		}
	}
	
	// ManagerPublic 
	//
	// The interface that a user can publish a capability to their sale
	// to allow others to access their sale
	access(all)
	resource interface ManagerPublic{ 
		access(all)
		fun purchase(
			listingID: UInt64,
			buyTokens: &{FungibleToken.Vault},
			databaseID: String,
			owner: Address,
			userPackCollection: &ARTIFACTPack.Collection,
			userCollection: &ARTIFACT.Collection,
			quantity: UInt64
		)
		
		access(all)
		fun purchaseOnPreSale(
			listingID: UInt64,
			buyTokens: &{FungibleToken.Vault},
			databaseID: String,
			owner: Address,
			userPackCollection: &ARTIFACTPack.Collection,
			userCollection: &ARTIFACT.Collection,
			quantity: UInt64
		)
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun getListings(): [Listing]
	}
	
	// MarketManager
	// An interface for adding and removing Listings within a ARTIFACTMarket,
	// intended for use by the ARTIFACTAdmin's own
	//
	access(all)
	resource interface MarketManager{ 
		// createListing
		// Allows the ARTIFACT owner to create and insert Listings.
		//
		access(all)
		fun createListing(
			nftID: UInt64?,
			nftTemplateID: UInt64?,
			packTemplateID: UInt64?,
			salePrice: UFix64,
			saleCuts: [
				SaleCut
			],
			salePaymentVaultType: Type,
			sellerCapability: Capability<&FUSD.Vault>,
			databaseID: String,
			whitelist: [
				Address
			],
			isPreSale: Bool,
			preSaleBuyerMaxLimit:{ 
				Address: UInt64
			}
		)
		
		// removeListing
		// Allows the ARTIFACTMarket owner to remove any sale listing, acepted or not.
		//
		access(all)
		fun removeListing(listingID: UInt64)
		
		// changePreSaleStatus
		// Allows the ARTIFACTMarket owner change pre-sale status.
		//
		access(all)
		fun changePreSaleStatus(listingID: UInt64, isPreSale: Bool)
	}
	
	access(all)
	resource Manager: ManagerPublic, MarketManager{ 
		
		/// A capability to create new packs
		access(self)
		var superAdminTokenReceiver: Capability<&ARTIFACTAdmin.AdminTokenReceiver>
		
		/// A collection of the nfts that the user has for sale 
		access(self)
		var ownerCollection: Capability<&ARTIFACT.Collection>
		
		access(self)
		var listings:{ UInt64: Listing}
		
		init(superAdminTokenReceiver: Capability<&ARTIFACTAdmin.AdminTokenReceiver>, ownerCollection: Capability<&ARTIFACT.Collection>){ 
			pre{ 
				(superAdminTokenReceiver.borrow()!).getSuperAdminRef() != nil:
					"Must be a super admin account"
			}
			self.superAdminTokenReceiver = superAdminTokenReceiver
			self.ownerCollection = ownerCollection
			self.listings ={} 
		}
		
		/// listForSale lists an NFT for sale in this sale collection
		/// at the specified price
		///
		/// Parameters: nftID: The NFT ID
		/// Parameters: nftTemplateID: The NFT template ID
		/// Parameters: packTemplateID: The Pack NFT template ID
		/// Parameters: salePrice: The sale price
		/// Parameters: saleCuts: The royalties applied on purchase
		/// Parameters: salePaymentVaultType: The vault type
		/// Parameters: sellerCapability: The seller capability to transfer FUSD
		/// Parameters: databaseID: The database id
		//
		access(all)
		fun createListing(nftID: UInt64?, nftTemplateID: UInt64?, packTemplateID: UInt64?, salePrice: UFix64, saleCuts: [SaleCut], salePaymentVaultType: Type, sellerCapability: Capability<&FUSD.Vault>, databaseID: String, whitelist: [Address], isPreSale: Bool, preSaleBuyerMaxLimit:{ Address: UInt64}){ 
			pre{ 
				nftID != nil || nftTemplateID != nil || packTemplateID != nil:
					"must pass one template ID"
				self.getNumberValue(value: nftID != nil) + self.getNumberValue(value: nftTemplateID != nil) + self.getNumberValue(value: packTemplateID != nil) == 1:
					"must pass only one template ID"
			}
			let listingID = ARTIFACTMarket.nextListingID
			ARTIFACTMarket.nextListingID = listingID + 1
			let listing = Listing(ID: listingID, nftID: nftID, nftTemplateID: nftTemplateID, packTemplateID: packTemplateID, salePrice: salePrice, saleCuts: saleCuts, salePaymentVaultType: salePaymentVaultType, sellerCapability: sellerCapability, whitelist: whitelist, isPreSale: isPreSale, preSaleBuyerMaxLimit: preSaleBuyerMaxLimit)
			self.listings[listingID] = listing
			let saleCutsInfo:{ Address: UFix64} ={} 
			for cut in saleCuts{ 
				saleCutsInfo[cut.receiver.address] = cut.percentage
			}
			emit ARTIFACTMarketListed(listingID: listingID, price: salePrice, saleCuts: saleCutsInfo, seller: self.owner?.address, databaseID: databaseID, nftID: nftID, nftTemplateID: nftTemplateID, packTemplateID: packTemplateID)
		}
		
		access(all)
		view fun getNumberValue(value: Bool): UInt64{ 
			if value == true{ 
				return 1
			}
			return 0
		}
		
		/// cancelSale cancels a sale and clears its price
		///
		/// Parameters: listingID: the ID of the listing to withdraw from the sale
		///
		access(all)
		fun removeListing(listingID: UInt64){ 
			// Remove the price from the prices dictionary
			self.listings.remove(key: listingID)
			
			// Emit the event for withdrawing a from the Sale
			emit ARTIFACTMarketListingRemoved(listingID: listingID, owner: self.owner?.address)
		}
		
		/// purchase lets a user send tokens to purchase an NFT that is for sale
		/// the purchased NFT is returned to the transaction context that called it
		///
		/// Parameters: listingID: the ID of the listing to purchase
		/// Parameters: buyTokens: the fungible tokens that are used to buy the NFT
		/// Parameters: databaseID: The database id
		/// Parameters: owner: The new owner of the pack
		/// Parameters: userPackCollection: The pack collection 
		/// Parameters: userCollection: The nft collection 
		/// Parameters: quantity: Quantity of pack to buy
		///
		access(all)
		fun purchase(listingID: UInt64, buyTokens: &{FungibleToken.Vault}, databaseID: String, owner: Address, userPackCollection: &ARTIFACTPack.Collection, userCollection: &ARTIFACT.Collection, quantity: UInt64){ 
			pre{ 
				!(self.listings[listingID]!).isPreSale:
					"sale is not available"
			}
			self.purchaseListing(listingID: listingID, buyTokens: buyTokens, databaseID: databaseID, owner: owner, userPackCollection: userPackCollection, userCollection: userCollection, quantity: quantity)
		}
		
		/// purchase pre sale lets a user send tokens to purchase an NFT that is for pre-sale 
		/// the purchased NFT is returned to the transaction context that called it
		///
		/// Parameters: listingID: the ID of the listing to purchase
		/// Parameters: buyTokens: the fungible tokens that are used to buy the NFT
		/// Parameters: databaseID: The database id
		/// Parameters: owner: The new owner of the pack
		/// Parameters: userPackCollection: The pack collection 
		/// Parameters: userCollection: The nft collection 
		/// Parameters: quantity: Quantity of pack to buy
		///
		access(all)
		fun purchaseOnPreSale(listingID: UInt64, buyTokens: &{FungibleToken.Vault}, databaseID: String, owner: Address, userPackCollection: &ARTIFACTPack.Collection, userCollection: &ARTIFACT.Collection, quantity: UInt64){ 
			pre{ 
				(self.listings[listingID]!).isPreSale:
					"sale is not available"
				(self.listings[listingID]!).whitelist.contains((userPackCollection.owner!).address):
					"sale available for users in whitelist"
				(userPackCollection.owner!).address == (userCollection.owner!).address:
					"Pack collection and User collection should be same wallet"
				self.checkBuyerMaxLimit(address: (userPackCollection.owner!).address, listingID: listingID, quantity: quantity):
					"pre-sale offer is not available for this wallet"
			}
			let listing = self.listings[listingID]!
			listing.increaseBuyers(userAddress: (userPackCollection.owner!).address, quantity: quantity)
			self.listings[listingID] = listing
			self.purchaseListing(listingID: listingID, buyTokens: buyTokens, databaseID: databaseID, owner: owner, userPackCollection: userPackCollection, userCollection: userCollection, quantity: quantity)
		}
		
		access(self)
		fun purchaseListing(listingID: UInt64, buyTokens: &{FungibleToken.Vault}, databaseID: String, owner: Address, userPackCollection: &ARTIFACTPack.Collection, userCollection: &ARTIFACT.Collection, quantity: UInt64){ 
			pre{ 
				quantity <= 6:
					"Max quantity is 6"
				self.listings.containsKey(listingID):
					"listingID not found"
				buyTokens.isInstance((self.listings[listingID]!).salePaymentVaultType):
					"payment vault is not requested fungible token"
			}
			var i: UInt64 = 0
			while i < quantity{ 
				if !self.listings.containsKey(listingID){ 
					panic("listing can't be purchase")
				}
				let listing = self.listings[listingID]!
				let price = listing.salePrice
				let buyerVault <- buyTokens.withdraw(amount: price)
				let nftTemplate = self.getTemplateInformation(listing: listing)
				var nft <- self.getNFT(nft: nftTemplate, owner: owner, listing: listing, quantity: quantity)
				for saleCut in listing.saleCuts{ 
					let receiverCut <- buyerVault.withdraw(amount: price * (saleCut.percentage / 100.0))
					(saleCut.receiver.borrow()!).deposit(from: <-receiverCut)
				}
				(listing.sellerCapability.borrow()!).deposit(from: <-buyerVault)
				emit ARTIFACTMarketPurchased(listingID: listingID, packID: nft.id, owner: owner, databaseID: databaseID)
				self.removeListingByGenericNFT(nft: nftTemplate, listing: listing)
				if listing.packTemplateID != nil{ 
					userPackCollection.deposit(token: <-nft)
				} else{ 
					userCollection.deposit(token: <-nft)
				}
				i = i + 1
			}
		}
		
		// getTemplateInformation based in the listing fields get the
		// NFT ID or NFT template ID or Pack NFT template struct
		//
		// Parameters: listing: The listing struct
		//
		// returns: AnyStruct the NFT reference
		access(self)
		fun getTemplateInformation(listing: Listing): AnyStruct{ 
			if listing.packTemplateID != nil{ 
				return ARTIFACTPack.getPackTemplate(templateId: listing.packTemplateID!)!
			} else if listing.nftID != nil{ 
				return listing.nftID
			} else if listing.nftTemplateID != nil{ 
				return listing.nftTemplateID
			}
			panic("Listing don't have any template information")
		}
		
		// checkBuyerMaxLimit function to check if wallet can buy on pre-sale
		access(self)
		view fun checkBuyerMaxLimit(address: Address, listingID: UInt64, quantity: UInt64): Bool{ 
			let listing = self.listings[listingID]!
			if listing.preSaleBuyerMaxLimit.containsKey(address){ 
				var quantityBuyer: UInt64 = 0
				if listing.buyers.containsKey(address){ 
					quantityBuyer = listing.buyers[address]!
				}
				return listing.preSaleBuyerMaxLimit[address]! >= quantityBuyer + quantity
			}
			return !listing.buyers.containsKey(address) && quantity == 1
		}
		
		// getNFT based in the listing fields get/create the
		// NFT or NFT template or Pack NFT
		//
		// Parameters: nft: The nft struct or NFT ID
		// Parameters: owner: The owner
		// Parameters: listing: The listing struct
		// Parameters: quantity: The quantity used to validate the maxQuantityPerTransaction
		//
		// returns: @NonFungibleToken.NFT the NFT or Pack
		access(self)
		fun getNFT(nft: AnyStruct, owner: Address, listing: Listing, quantity: UInt64): @{NonFungibleToken.NFT}{ 
			if listing.packTemplateID != nil{ 
				let packTemplate = nft as! ARTIFACTPack.PackTemplate
				if packTemplate.maxQuantityPerTransaction < quantity{ 
					panic("quantity is greater than max quantity")
				}
				let adminRef = (self.superAdminTokenReceiver.borrow()!).getAdminRef()!
				let adminOpenerRef = (self.superAdminTokenReceiver.borrow()!).getAdminOpenerRef()
				return <-adminRef.createPack(packTemplate: packTemplate, adminRef: adminOpenerRef, owner: owner, listingID: listing.ID)
			} else if listing.nftID != nil{ 
				return <-(self.ownerCollection.borrow()!).withdraw(withdrawID: listing.nftID!)
			} else if listing.nftTemplateID != nil{ 
				let adminRef = (self.superAdminTokenReceiver.borrow()!).getAdminRef()!
				return <-adminRef.mintNFT(templateId: listing.nftTemplateID!, packID: 0, owner: owner)
			}
			panic("Error to get NFT from template")
		}
		
		// removeListingByGenericNFT based in the listing fields remove the sale offer
		//
		// Parameters: nft: The nft struct or NFT ID
		// Parameters: listing: The listing struct
		//
		access(self)
		fun removeListingByGenericNFT(nft: AnyStruct, listing: Listing){ 
			if listing.packTemplateID != nil{ 
				let packTemplate = nft as! ARTIFACTPack.PackTemplate
				if packTemplate.totalSupply <= ARTIFACTPack.numberMintedByPack[listing.ID]!{ 
					self.removeListing(listingID: listing.ID)
				}
			} else if listing.nftID != nil{ 
				self.removeListing(listingID: listing.ID)
			} else if listing.nftTemplateID != nil{ 
				let template = ARTIFACT.getTemplate(templateId: listing.nftTemplateID!)!
				let numberMintedByTemplate = ARTIFACT.getNumberMintedByTemplate(templateId: listing.nftTemplateID!)!
				if template.maxEditions <= numberMintedByTemplate{ 
					self.removeListing(listingID: listing.ID)
				}
			} else{ 
				panic("Error to remove listing from template")
			}
		}
		
		/// getIDs returns an array of token IDs that are for sale
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.listings.keys
		}
		
		/// getListings returns an array of Listing that are for sale
		access(all)
		fun getListings(): [Listing]{ 
			return self.listings.values
		}
		
		access(all)
		fun changePreSaleStatus(listingID: UInt64, isPreSale: Bool){ 
			pre{ 
				self.listings.containsKey(listingID):
					"listingID not found"
			}
			(self.listings[listingID]!).changePreSaleStatus(isPreSale: isPreSale)
		}
	}
	
	// -----------------------------------------------------------------------
	// ARTIFACTMarket contract-level function definitions
	// -----------------------------------------------------------------------
	// createManager creates a new Manager resource
	//
	access(all)
	fun createManager(
		superAdminTokenReceiver: Capability<&ARTIFACTAdmin.AdminTokenReceiver>,
		ownerCollection: Capability<&ARTIFACT.Collection>
	): @Manager{ 
		return <-create Manager(
			superAdminTokenReceiver: superAdminTokenReceiver,
			ownerCollection: ownerCollection
		)
	}
	
	// createSaleCut creates a new SaleCut to a receiver user
	// with a specific percentage.
	//
	access(all)
	fun createSaleCut(receiver: Capability<&FUSD.Vault>, percentage: UFix64): SaleCut{ 
		return SaleCut(receiver: receiver, percentage: percentage)
	}
	
	// totalSaleCuts sum all percentages in a array of SaleCut
	//
	access(all)
	view fun totalSaleCuts(saleCuts: [SaleCut]): UFix64{ 
		var total: UFix64 = 0.0
		for cut in saleCuts{ 
			total = cut.percentage + total
		}
		return total
	}
	
	init(){ 
		self.marketStoragePath = /storage/ARTIFACTMarketCollection
		self.marketPublicPath = /public/ARTIFACTMarketCollection
		self.managerPath = /storage/ARTIFACTMarketManager
		self.nextListingID = 1
		if self.account.storage.borrow<&{ARTIFACTPack.CollectionPublic}>(
			from: ARTIFACTPack.collectionStoragePath
		)
		== nil{ 
			let collection <- ARTIFACTPack.createEmptyCollection() as! @ARTIFACTPack.Collection
			self.account.storage.save<@ARTIFACTPack.Collection>(
				<-collection,
				to: ARTIFACTPack.collectionStoragePath
			)
			var capability_1 =
				self.account.capabilities.storage.issue<&{ARTIFACTPack.CollectionPublic}>(
					ARTIFACTPack.collectionStoragePath
				)
			self.account.capabilities.publish(capability_1, at: ARTIFACTPack.collectionPublicPath)
		}
		if self.account.storage.borrow<&{ARTIFACTMarket.ManagerPublic}>(
			from: ARTIFACTMarket.marketStoragePath
		)
		== nil{ 
			var capability_2 =
				self.account.capabilities.storage.issue<&ARTIFACT.Collection>(
					ARTIFACT.collectionStoragePath
				)
			self.account.capabilities.publish(capability_2, at: ARTIFACT.collectionPrivatePath)
			let ownerCollection = capability_2
			var capability_3 =
				self.account.capabilities.storage.issue<&ARTIFACTAdmin.AdminTokenReceiver>(
					ARTIFACTAdmin.ARTIFACTAdminTokenReceiverStoragePath
				)
			self.account.capabilities.publish(
				capability_3,
				at: ARTIFACTAdmin.ARTIFACTAdminTokenReceiverPrivatePath
			)
			let superAdminTokenReceiverCapability = capability_3
			self.account.storage.save(
				<-create ARTIFACTMarket.Manager(
					superAdminTokenReceiver: superAdminTokenReceiverCapability,
					ownerCollection: ownerCollection
				),
				to: ARTIFACTMarket.marketStoragePath
			)
			var capability_4 =
				self.account.capabilities.storage.issue<&ARTIFACTMarket.Manager>(
					ARTIFACTMarket.marketStoragePath
				)
			self.account.capabilities.publish(capability_4, at: ARTIFACTMarket.marketPublicPath)
		}
	}
}
