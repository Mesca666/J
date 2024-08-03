/*
This is a multifaceted contract that sets up an auction resource, the parameters for 
running an auctions and setting up an account storefront to store all active auctions
 */

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import NFluence from "./NFluence.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

access(all)
contract NFluenceAuction{ 
	
	// The total amount of AuctionItems that have been created
	access(all)
	var totalAuctions: UInt64
	
	// The percentage of the final sale price that gets allocated to the platform 
	access(account)
	var cutPercentage: UFix64
	
	access(account)
	let cutVault: @{FungibleToken.Vault}
	
	access(all)
	let NFluenceAuctionStorefrontStoragePath: StoragePath
	
	access(all)
	let NFluenceAuctionStorefrontPublicPath: PublicPath
	
	access(all)
	let NFluenceAuctionAdminStorage: StoragePath
	
	access(all)
	event NFluenceAuctionContractInitialized()
	
	access(all)
	event AuctionCreated(tokenID: UInt64, auctionID: UInt64, user: Address, startPrice: UFix64)
	
	access(all)
	event BidPlaced(tokenID: UInt64?, user: Address, bidPrice: UFix64, owner: Address)
	
	access(all)
	event BidReceived(tokenID: UInt64?, user: Address, bidPrice: UFix64)
	
	access(all)
	event Settled(
		tokenID: UInt64?,
		auctionID: UInt64,
		price: UFix64,
		user: Address,
		winner: Address?
	)
	
	access(all)
	event SettledNoBids(tokenID: UInt64, auctionID: UInt64, user: Address)
	
	access(all)
	event Canceled(tokenID: UInt64, auctionID: UInt64, user: Address)
	
	access(all)
	event StorefrontInitialized(storefrontResourceID: UInt64)
	
	access(all)
	event StorefrontDestroyed(storefrontResourceID: UInt64)
	
	// This struct contains most of the critical data pertaining to a particular auction
	access(all)
	struct AuctionData{ 
		
		// Unique id for a single auction
		// Should match total auctions at time of creation
		access(all)
		let auctionId: UInt64
		
		// Current price of the NFT that's being auctioned
		access(all)
		let price: UFix64
		
		// Current number of bids for this auction
		access(all)
		let numBids: UInt64
		
		access(all)
		let timeRemaining: Fix64
		
		access(all)
		let endTime: UFix64
		
		access(all)
		let startTime: UFix64
		
		// NFT metadata
		access(self)
		let nftData: NFluence.NFluenceNFTData?
		
		// The address of the user with the current winning bid
		access(all)
		let leader: Address?
		
		// Used as an input check for bids
		access(all)
		let minNextBid: UFix64
		
		access(all)
		let settled: Bool
		
		// Expired means the time remaining to bid has elapsed, but the auction may still not be settled
		access(all)
		let expired: Bool
		
		init(
			auctionId: UInt64,
			currentPrice: UFix64,
			timeRemaining: Fix64,
			nftData: NFluence.NFluenceNFTData?,
			leader: Address?,
			startTime: UFix64,
			endTime: UFix64,
			minNextBid: UFix64,
			completed: Bool,
			expired: Bool,
			numBids: UInt64
		){ 
			self.auctionId = auctionId
			self.price = currentPrice
			self.numBids = numBids
			self.timeRemaining = timeRemaining
			self.nftData = nftData
			self.leader = leader
			self.startTime = startTime
			self.endTime = endTime
			self.minNextBid = minNextBid
			self.settled = completed
			self.expired = expired
		}
	}
	
	// Data that applies to a particular bid made by a user on an NFT currently in a live auction
	access(all)
	struct Bid{ 
		// The order in which this bid was made, starting at 0
		access(all)
		let bidSequence: UInt64
		
		access(all)
		let bidAmount: UFix64
		
		// Capability to the vault that contains the token the NFT owner will receive if this bid wins the auction
		access(all)
		let bidder: Address
		
		init(
			bidSequence: UInt64,
			bidAmount: UFix64,
			bidderReceiver: Capability<&{FungibleToken.Receiver}>
		){ 
			self.bidSequence = bidSequence
			self.bidAmount = bidAmount
			self.bidder = ((bidderReceiver.borrow()!).owner!).address
		}
	}
	
	access(all)
	resource interface AuctionPublic{ 
		access(all)
		fun getNFTData(): NFluence.NFluenceNFTData?
		
		access(all)
		fun getBidHistory(): [Bid]
		
		access(all)
		fun currentHighestBidder(): Address
		
		access(all)
		view fun timeRemaining(): Fix64
		
		access(all)
		fun isAuctionExpired(): Bool
		
		access(all)
		view fun minNextBid(): UFix64
		
		access(all)
		fun currentBidForUser(address: Address): UFix64
		
		access(all)
		fun getAuctionData(): AuctionData
		
		access(all)
		fun placeBid(
			bidTokens: @{FungibleToken.Vault},
			vaultCap: Capability<&{FungibleToken.Receiver}>,
			collectionCap: Capability<&{NFluence.NFluenceCollectionPublic}>
		)
	}
	
	// AuctionItem contains the Resources and metadata for a single auction
	// Functions pertaining to auctions
	access(all)
	resource AuctionItem: AuctionPublic{ 
		
		// Number of bids made, that is aggregated to the data struct
		access(all)
		var numberOfBids: UInt64
		
		// The Item that is sold at this auction
		access(all)
		var nftId: UInt64
		
		// Bid history is stored on chain
		access(contract)
		var bidHistory: [Bid]
		
		// This is the escrow vault that holds the tokens for the current largest bid
		access(all)
		let bidVault: @{FungibleToken.Vault}
		
		// The id of this individual auction
		access(all)
		let auctionID: UInt64
		
		// The minimum increase in price a new bid on the auction must conform to
		// At the moment this is set at $1 but eventually the functionality for the user to customize this value will exist
		access(all)
		let minimumBidIncrement: Int32
		
		// The time the auction should start at
		access(all)
		var auctionStartTime: UFix64
		
		//The length in seconds for this auction
		access(all)
		var auctionLength: UFix64
		
		// If true the auction has been fully settled
		access(all)
		var auctionCompleted: Bool
		
		access(all)
		var startPrice: UFix64
		
		access(all)
		var currentPrice: UFix64
		
		// The capability that points to the resource where you want the NFT transfered to if you win this auction 
		access(self)
		var recipientCollectionCap: Capability<&{NFluence.NFluenceCollectionPublic}>
		
		// The capablity to send the escrow bidVault back to if you are outbid
		access(self)
		var recipientVaultCap: Capability<&{FungibleToken.Receiver}>
		
		// The capability for the owner of the NFT to return the item to if the auction is cancelled or settled without a bid
		access(self)
		let ownerCollectionCap: Capability<&NFluence.Collection>
		
		// The capability to pay the owner of the item when the auction is done
		access(self)
		let ownerVaultCap: Capability<&{FungibleToken.Receiver}>
		
		init(nftId: UInt64, minimumBidIncrement: Int32, auctionStartTime: UFix64, startPrice: UFix64, auctionLength: UFix64, ownerCollectionCap: Capability<&NFluence.Collection>, ownerVaultCap: Capability<&{FungibleToken.Receiver}>){ 
			self.nftId = nftId
			self.bidVault <- FUSD.createEmptyVault(vaultType: Type<@FUSD.Vault>())
			self.auctionID = NFluenceAuction.totalAuctions
			self.minimumBidIncrement = minimumBidIncrement
			self.auctionLength = auctionLength
			self.startPrice = startPrice
			self.currentPrice = startPrice
			self.auctionStartTime = auctionStartTime
			self.auctionCompleted = false
			// recipient collection and vault capabilities set to the owner collection and vault capabilities
			// initially so that if the auction is settled without a bid then the NFT and vault tokens would go back to the original owner
			self.recipientCollectionCap = ownerCollectionCap
			self.recipientVaultCap = ownerVaultCap
			self.ownerCollectionCap = ownerCollectionCap
			self.ownerVaultCap = ownerVaultCap
			self.numberOfBids = 0
			self.bidHistory = []
			NFluenceAuction.totalAuctions = NFluenceAuction.totalAuctions + 1 as UInt64
		}
		
		// Function to get the metadata of the NFT being auctioned
		access(all)
		fun getNFTData(): NFluence.NFluenceNFTData?{ 
			let ref = self.ownerCollectionCap.borrow()!
			let data = ref.getTokenData(id: self.nftId)
			return data
		}
		
		access(all)
		fun getBidHistory(): [Bid]{ 
			return self.bidHistory
		}
		
		// Sends the NFT to the Collection belonging to the provided Capability
		access(contract)
		fun sendNFTToWinner(){ 
			let ref = self.ownerCollectionCap.borrow()!
			let nft <- ref.withdraw(withdrawID: self.nftId)
			let collectionRef = self.recipientCollectionCap.borrow()!
			collectionRef.deposit(token: <-nft)
		}
		
		// sendBidTokens sends the bid tokens to the Vault Receiver belonging to the provided Capability
		access(contract)
		fun sendBidTokensToOwner(){ 
			if let vaultRef = self.ownerVaultCap.borrow(){ 
				let bidVaultRef = &self.bidVault as &{FungibleToken.Vault}
				if bidVaultRef.balance > 0.0{ 
					vaultRef.deposit(from: <-bidVaultRef.withdraw(amount: bidVaultRef.balance))
				}
			}
		}
		
		access(contract)
		fun releasePreviousBid(){ 
			if let vaultRef = self.recipientVaultCap.borrow(){ 
				let bidVaultRef = &self.bidVault as &{FungibleToken.Vault}
				if bidVaultRef.balance > 0.0{ 
					vaultRef.deposit(from: <-bidVaultRef.withdraw(amount: bidVaultRef.balance))
				}
			}
		}
		
		access(all)
		fun currentHighestBidder(): Address{ 
			return ((self.recipientVaultCap.borrow()!).owner!).address
		}
		
		// If an auction is settled with no bids or cancelled
		access(self)
		fun returnNFTToOwner(){ 
			
			// release any bidder's tokens
			if self.numberOfBids > 0{ 
				self.releasePreviousBid()
			}
			// deposit the NFT back into the owner's collection
			self.auctionCompleted = true
		}
		
		// Sends NFT to the hightest bidder or back to the original owner if no bids
		// Resolves all transfer of bid funds as well
		access(contract)
		fun settleAuction(){ 
			pre{ 
				!self.auctionCompleted:
					"This auction has already been settled"
			}
			let sellerAddress = ((self.ownerVaultCap.borrow()!).owner!).address
			let buyerAddress = self.currentHighestBidder()
			
			// Return item to owner if there are no bids to settle
			if self.numberOfBids == 0 as UInt64{ 
				self.returnNFTToOwner()
				emit SettledNoBids(tokenID: self.nftId, auctionID: self.auctionID, user: sellerAddress)
				return
			}
			
			// Withdraw the contracts cut of the winning bids funds
			let cutAmount = self.currentPrice * (NFluenceAuction.cutPercentage / 100.0)
			let cutTokens <- self.bidVault.withdraw(amount: cutAmount)
			NFluenceAuction.cutVault.deposit(from: <-cutTokens)
			self.sendNFTToWinner()
			self.sendBidTokensToOwner()
			self.auctionCompleted = true
			emit Settled(tokenID: self.nftId, auctionID: self.auctionID, price: self.currentPrice, user: sellerAddress, winner: buyerAddress)
		}
		
		// This can be negative if the auction has expired
		access(all)
		view fun timeRemaining(): Fix64{ 
			return Fix64(self.auctionStartTime + self.auctionLength) - Fix64(getCurrentBlock().timestamp)
		}
		
		access(all)
		fun isAuctionExpired(): Bool{ 
			let timeRemaining = self.timeRemaining()
			return timeRemaining < Fix64(0.0)
		}
		
		access(all)
		view fun minNextBid(): UFix64{ 
			return self.currentPrice + UFix64(self.minimumBidIncrement)
		}
		
		// Extend an auction with a given set of seconds
		access(self)
		fun extendWith(_ amount: UFix64){ 
			self.auctionLength = self.auctionLength + amount
		}
		
		// Returns the last bid made by a user regardless of if it's the current winning bid
		access(all)
		fun currentBidForUser(address: Address): UFix64{ 
			if self.currentHighestBidder() == address{ 
				return self.bidVault.balance
			}
			for bid in self.bidHistory{ 
				if bid.bidder == address{ 
					return bid.bidAmount
				}
			}
			return 0.0
		}
		
		access(contract)
		fun cancelAuction(){ 
			emit Canceled(tokenID: self.nftId, auctionID: self.auctionID, user: ((self.ownerVaultCap.borrow()!).owner!).address)
			self.returnNFTToOwner()
			self.auctionCompleted = true
		}
		
		access(all)
		fun placeBid(bidTokens: @{FungibleToken.Vault}, vaultCap: Capability<&{FungibleToken.Receiver}>, collectionCap: Capability<&{NFluence.NFluenceCollectionPublic}>){ 
			pre{ 
				!self.auctionCompleted:
					"The auction is already settled"
				//self.NFT != nil: "NFT in auction does not exist"
				self.timeRemaining() > 0.0:
					"Time to place bids has elapsed"
				bidTokens.balance >= self.minNextBid():
					"Bid amount must be larger or equal to the current price + minimum bid increment"
			}
			let bidderAddress = ((vaultCap.borrow()!).owner!).address
			let ownerAddress = ((self.ownerCollectionCap.borrow()!).owner!).address
			
			// Send current tokens in bid vault back to previous bidder
			self.releasePreviousBid()
			
			// Deposit new bid tokens
			self.bidVault.deposit(from: <-bidTokens)
			self.recipientVaultCap = vaultCap
			self.currentPrice = self.bidVault.balance
			
			// Add the bidder's Vault and NFT receiver references
			self.recipientCollectionCap = collectionCap
			let element = Bid(bidSequence: self.numberOfBids, bidAmount: self.bidVault.balance, bidderReceiver: vaultCap)
			self.bidHistory.insert(at: self.numberOfBids, element)
			self.numberOfBids = self.numberOfBids + 1 as UInt64
			
			// If there's less than ~10 minutes left in the auction the time gets extended
			if self.timeRemaining() < 600.0{ 
				let timeToExtend = 600.0 as Fix64 - self.timeRemaining()
				self.extendWith(UFix64(timeToExtend))
			}
			emit BidPlaced(tokenID: self.nftId, user: bidderAddress, bidPrice: self.currentPrice, owner: ownerAddress)
			emit BidReceived(tokenID: self.nftId, user: ownerAddress, bidPrice: self.currentPrice)
		}
		
		access(all)
		fun getAuctionData(): AuctionData{ 
			return AuctionData(auctionId: self.auctionID, currentPrice: self.currentPrice, timeRemaining: self.timeRemaining(), nftData: self.getNFTData(), leader: ((self.recipientCollectionCap.borrow()!).owner!).address, startTime: self.auctionStartTime, endTime: self.auctionStartTime + self.auctionLength, minNextBid: self.minNextBid(), completed: self.auctionCompleted, expired: self.isAuctionExpired(), numBids: self.numberOfBids)
		}
	}
	
	access(all)
	resource interface StorefrontPublic{ 
		access(all)
		fun getListingIDs(): [UInt64]
		
		access(all)
		fun borrowListing(listingResourceID: UInt64): &AuctionItem?
	}
	
	access(all)
	resource Storefront: StorefrontPublic{ 
		access(self)
		var listings: @{UInt64: AuctionItem}
		
		access(all)
		fun createAuction(token: UInt64, minimumBidIncrement: Int32, auctionLength: UFix64, auctionStartTime: UFix64, startPrice: UFix64, collectionCap: Capability<&NFluence.Collection>, vaultCap: Capability<&{FungibleToken.Receiver}>){ 
			let listing <- create AuctionItem(nftId: token, minimumBidIncrement: minimumBidIncrement, auctionStartTime: auctionStartTime, startPrice: startPrice, auctionLength: auctionLength, ownerCollectionCap: collectionCap, ownerVaultCap: vaultCap)
			let auctionID = listing.auctionID
			let listingPrice = listing.getAuctionData().price
			let creatorAddress = (listing.getNFTData()!).creatorAddress
			let listingResourceID = listing.nftId
			
			// Add the new listing to the dictionary.
			let oldListing <- self.listings[listingResourceID] <- listing
			destroy oldListing
			emit AuctionCreated(tokenID: listingResourceID, auctionID: auctionID, user: creatorAddress, startPrice: listingPrice)
		}
		
		// Remove a Listing that has not yet been purchased from the collection and destroy it.
		access(all)
		fun removeListing(listingResourceID: UInt64){ 
			if self.checkIdInListing(tokenId: listingResourceID){ 
				let listing <- self.listings.remove(key: listingResourceID)!
				listing.cancelAuction()
				destroy listing
			}
			return
		}
		
		access(all)
		fun checkIdInListing(tokenId: UInt64): Bool{ 
			return self.listings.containsKey(tokenId)
		}
		
		access(all)
		fun settleListing(listingResourceID: UInt64){ 
			let listing <- self.listings.remove(key: listingResourceID) ?? panic("missing Listing")
			listing.settleAuction()
			destroy listing
		}
		
		access(all)
		fun getListingIDs(): [UInt64]{ 
			return self.listings.keys
		}
		
		access(all)
		fun borrowListing(listingResourceID: UInt64): &AuctionItem?{ 
			if self.listings[listingResourceID] != nil{ 
				return &self.listings[listingResourceID] as &NFluenceAuction.AuctionItem?
			} else{ 
				return nil
			}
		}
		
		init(){ 
			self.listings <-{} 
			emit StorefrontInitialized(storefrontResourceID: self.uuid)
		}
	}
	
	access(all)
	fun createStorefront(): @Storefront{ 
		return <-create Storefront()
	}
	
	// An admin resource that contains administrative functions for this contract
	access(all)
	resource Administrator{ 
		access(self)
		fun updateCutPercentage(newPercentage: UFix64){ 
			pre{ 
				newPercentage > 1.0:
					"New percentage must be between 1 and 100"
			}
			NFluenceAuction.cutPercentage = newPercentage
		}
		
		access(self)
		fun retrieveCutVault(): @{FungibleToken.Vault}{ 
			let cutVaultAmount = NFluenceAuction.cutVault.balance
			return <-NFluenceAuction.cutVault.withdraw(amount: cutVaultAmount)
		}
	}
	
	init(){ 
		self.NFluenceAuctionStorefrontStoragePath = /storage/NFluenceAuctionStorefrontStorage
		self.NFluenceAuctionStorefrontPublicPath = /public/NFluenceAuctionStorefrontPublic
		self.NFluenceAuctionAdminStorage = /storage/NFluenceAuctionAdminStorage
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.NFluenceAuctionAdminStorage)
		self.cutVault <- FUSD.createEmptyVault(vaultType: Type<@FUSD.Vault>())
		emit NFluenceAuctionContractInitialized()
		self.totalAuctions = 0 as UInt64
		self.cutPercentage = 20.0
	}
}
