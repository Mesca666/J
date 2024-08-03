/*
* Inspiration: https://flow-view-source.com/testnet/account/0xba1132bc08f82fe2/contract/Ghost
*/

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract Profile{ 
	access(all)
	let publicPath: PublicPath
	
	access(all)
	let storagePath: StoragePath
	
	//and event emitted when somebody follows another user
	access(all)
	event Follow(follower: Address, following: Address, tags: [String])
	
	//an event emitted when somebody unfollows somebody
	access(all)
	event Unfollow(follower: Address, unfollowing: Address)
	
	//and event emitted when a user verifies something
	access(all)
	event Verification(account: Address, message: String)
	
	/* 
		Represents a Fungible token wallet with a name and a supported type.
		*/
	
	access(all)
	struct Wallet{ 
		access(all)
		let name: String
		
		access(all)
		let receiver: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let balance: Capability<&{FungibleToken.Balance}>
		
		access(all)
		let accept: Type
		
		access(all)
		let tags: [String]
		
		init(
			name: String,
			receiver: Capability<&{FungibleToken.Receiver}>,
			balance: Capability<&{FungibleToken.Balance}>,
			accept: Type,
			tags: [
				String
			]
		){ 
			self.name = name
			self.receiver = receiver
			self.balance = balance
			self.accept = accept
			self.tags = tags
		}
	}
	
	/*
	
		Represent a collection of a Resource that you want to expose
		Since NFT standard is not so great at just add Type and you have to use instanceOf to check for now
		*/
	
	access(all)
	struct ResourceCollection{ 
		access(all)
		let collection: Capability
		
		access(all)
		let tags: [String]
		
		access(all)
		let type: Type
		
		access(all)
		let name: String
		
		init(name: String, collection: Capability, type: Type, tags: [String]){ 
			self.name = name
			self.collection = collection
			self.tags = tags
			self.type = type
		}
	}
	
	access(all)
	struct CollectionProfile{ 
		access(all)
		let tags: [String]
		
		access(all)
		let type: String
		
		access(all)
		let name: String
		
		init(_ collection: ResourceCollection){ 
			self.name = collection.name
			self.type = collection.type.identifier
			self.tags = collection.tags
		}
	}
	
	/*
		A link that you could add to your profile
		*/
	
	access(all)
	struct Link{ 
		access(all)
		let url: String
		
		access(all)
		let title: String
		
		access(all)
		let type: String
		
		init(title: String, type: String, url: String){ 
			self.url = url
			self.title = title
			self.type = type
		}
	}
	
	/*
		Information about a connection between one profile and another.
		*/
	
	access(all)
	struct FriendStatus{ 
		access(all)
		let follower: Address
		
		access(all)
		let following: Address
		
		access(all)
		let tags: [String]
		
		init(follower: Address, following: Address, tags: [String]){ 
			self.follower = follower
			self.following = following
			self.tags = tags
		}
	}
	
	access(all)
	struct WalletProfile{ 
		access(all)
		let name: String
		
		access(all)
		let balance: UFix64
		
		access(all)
		let accept: String
		
		access(all)
		let tags: [String]
		
		init(_ wallet: Wallet){ 
			self.name = wallet.name
			self.balance = wallet.balance.borrow()?.balance ?? 0.0
			self.accept = wallet.accept.identifier
			self.tags = wallet.tags
		}
	}
	
	access(all)
	struct UserProfile{ 
		access(all)
		let address: Address
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let tags: [String]
		
		access(all)
		let avatar: String
		
		access(all)
		let links: [Link]
		
		access(all)
		let wallets: [WalletProfile]
		
		access(all)
		let collections: [CollectionProfile]
		
		access(all)
		let following: [FriendStatus]
		
		access(all)
		let followers: [FriendStatus]
		
		access(all)
		let allowStoringFollowers: Bool
		
		init(
			address: Address,
			name: String,
			description: String,
			tags: [
				String
			],
			avatar: String,
			links: [
				Link
			],
			wallets: [
				WalletProfile
			],
			collections: [
				CollectionProfile
			],
			following: [
				FriendStatus
			],
			followers: [
				FriendStatus
			],
			allowStoringFollowers: Bool
		){ 
			self.address = address
			self.name = name
			self.description = description
			self.tags = tags
			self.avatar = avatar
			self.links = links
			self.collections = collections
			self.wallets = wallets
			self.following = following
			self.followers = followers
			self.allowStoringFollowers = allowStoringFollowers
		}
	}
	
	access(all)
	resource interface Public{ 
		access(all)
		fun getName(): String
		
		access(all)
		fun getDescription(): String
		
		access(all)
		fun getTags(): [String]
		
		access(all)
		fun getAvatar(): String
		
		access(all)
		fun getCollections(): [ResourceCollection]
		
		access(all)
		fun follows(_ address: Address): Bool
		
		access(all)
		fun getFollowers(): [FriendStatus]
		
		access(all)
		fun getFollowing(): [FriendStatus]
		
		access(all)
		fun getWallets(): [Wallet]
		
		access(all)
		fun getLinks(): [Link]
		
		//TODO: create another method to deposit with message
		access(all)
		fun deposit(from: @{FungibleToken.Vault})
		
		access(all)
		fun supportedFungigleTokenTypes(): [Type]
		
		access(all)
		fun asProfile(): UserProfile
		
		access(all)
		fun isBanned(_ val: Address): Bool
		
		//TODO: should getBanned be here?
		access(contract)
		fun internal_addFollower(_ val: FriendStatus)
		
		access(contract)
		fun internal_removeFollower(_ address: Address)
	}
	
	access(all)
	resource interface Owner{ 
		access(all)
		fun setName(_ val: String){ 
			pre{ 
				val.length <= 16:
					"Name must be 16 or less characters"
			}
		}
		
		access(all)
		fun setAvatar(_ val: String){ 
			pre{ 
				val.length <= 255:
					"Avatar must be 255 characters or less"
			}
		}
		
		access(all)
		fun setTags(_ val: [String]){ 
			pre{ 
				Profile.verifyTags(tags: val, tagLength: 10, tagSize: 3):
					"cannot have more then 3 tags of length 10"
			}
		}
		
		//validate length of description to be 255 or something?
		access(all)
		fun setDescription(_ val: String){ 
			pre{ 
				val.length <= 255:
					"Description must be 255 characters or less"
			}
		}
		
		access(all)
		fun follow(_ address: Address, tags: [String]){ 
			pre{ 
				Profile.verifyTags(tags: tags, tagLength: 10, tagSize: 3):
					"cannot have more then 3 tags of length 10"
			}
		}
		
		access(all)
		fun unfollow(_ address: Address)
		
		access(all)
		fun removeCollection(_ val: String)
		
		access(all)
		fun addCollection(_ val: ResourceCollection)
		
		access(all)
		fun addWallet(_ val: Wallet)
		
		access(all)
		fun removeWallet(_ val: String)
		
		access(all)
		fun setWallets(_ val: [Wallet])
		
		access(all)
		fun addLink(_ val: Link)
		
		access(all)
		fun removeLink(_ val: String)
		
		//Verify that this user has signed something.
		access(all)
		fun verify(_ val: String)
		
		//A user must be able to remove a follower since this data in your account is added there by another user
		access(all)
		fun removeFollower(_ val: Address)
		
		//manage bans
		access(all)
		fun addBan(_ val: Address)
		
		access(all)
		fun removeBan(_ val: Address)
		
		access(all)
		fun getBans(): [Address]
		
		//Set if user is allowed to store followers or now
		access(all)
		fun setAllowStoringFollowers(_ val: Bool)
	}
	
	access(all)
	resource User: Public, Owner, FungibleToken.Receiver{ 
		access(self)
		var name: String
		
		access(self)
		var description: String
		
		access(self)
		var avatar: String
		
		access(self)
		var tags: [String]
		
		access(self)
		var followers:{ Address: FriendStatus}
		
		access(self)
		var bans:{ Address: Bool}
		
		access(self)
		var following:{ Address: FriendStatus}
		
		access(self)
		var collections:{ String: ResourceCollection}
		
		access(self)
		var wallets: [Wallet]
		
		access(self)
		var links:{ String: Link}
		
		access(self)
		var allowStoringFollowers: Bool
		
		init(name: String, description: String, allowStoringFollowers: Bool, tags: [String]){ 
			self.name = name
			self.description = description
			self.tags = tags
			self.avatar = "https://avatars.onflow.org/avatar/ghostnote"
			self.followers ={} 
			self.following ={} 
			self.collections ={} 
			self.wallets = []
			self.links ={} 
			self.allowStoringFollowers = allowStoringFollowers
			self.bans ={} 
		}
		
		access(all)
		fun addBan(_ val: Address){ 
			self.bans[val] = true
		}
		
		access(all)
		fun removeBan(_ val: Address){ 
			self.bans.remove(key: val)
		}
		
		access(all)
		fun getBans(): [Address]{ 
			return self.bans.keys
		}
		
		access(all)
		fun isBanned(_ val: Address): Bool{ 
			return self.bans.containsKey(val)
		}
		
		access(all)
		fun setAllowStoringFollowers(_ val: Bool){ 
			self.allowStoringFollowers = val
		}
		
		access(all)
		fun verify(_ val: String){ 
			emit Verification(account: (self.owner!).address, message: val)
		}
		
		access(all)
		fun asProfile(): UserProfile{ 
			let wallets: [WalletProfile] = []
			for w in self.wallets{ 
				wallets.append(WalletProfile(w))
			}
			let collections: [CollectionProfile] = []
			for c in self.getCollections(){ 
				collections.append(CollectionProfile(c))
			}
			return UserProfile(address: (self.owner!).address, name: self.getName(), description: self.getDescription(), tags: self.getTags(), avatar: self.getAvatar(), links: self.getLinks(), wallets: wallets, collections: collections, following: self.getFollowing(), followers: self.getFollowers(), allowStoringFollowers: self.allowStoringFollowers)
		}
		
		access(all)
		fun getLinks(): [Link]{ 
			return self.links.values
		}
		
		access(all)
		fun addLink(_ val: Link){ 
			self.links[val.title] = val
		}
		
		access(all)
		fun removeLink(_ val: String){ 
			self.links.remove(key: val)
		}
		
		access(all)
		fun supportedFungigleTokenTypes(): [Type]{ 
			let types: [Type] = []
			for w in self.wallets{ 
				if !types.contains(w.accept){ 
					types.append(w.accept)
				}
			}
			return types
		}
		
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			for w in self.wallets{ 
				if from.isInstance(w.accept){ 
					(w.receiver.borrow()!).deposit(from: <-from)
					return
				}
			}
			let identifier = from.getType().identifier
			//TODO: I need to destroy here for this to compile, but WHY?
			destroy from
			panic("could not find a supported wallet for:".concat(identifier))
		}
		
		access(all)
		fun getWallets(): [Wallet]{ 
			return self.wallets
		}
		
		access(all)
		fun addWallet(_ val: Wallet){ 
			self.wallets.append(val)
		}
		
		access(all)
		fun removeWallet(_ val: String){ 
			let numWallets = self.wallets.length
			var i = 0
			while i < numWallets{ 
				if self.wallets[i].name == val{ 
					self.wallets.remove(at: i)
					return
				}
				i = i + 1
			}
		}
		
		access(all)
		fun setWallets(_ val: [Wallet]){ 
			self.wallets = val
		}
		
		access(all)
		fun removeFollower(_ val: Address){ 
			self.followers.remove(key: val)
		}
		
		access(all)
		fun follows(_ address: Address): Bool{ 
			return self.following.containsKey(address)
		}
		
		access(all)
		fun getName(): String{ 
			return self.name
		}
		
		access(all)
		fun getDescription(): String{ 
			return self.description
		}
		
		access(all)
		fun getTags(): [String]{ 
			return self.tags
		}
		
		access(all)
		fun getAvatar(): String{ 
			return self.avatar
		}
		
		access(all)
		fun getFollowers(): [FriendStatus]{ 
			return self.followers.values
		}
		
		access(all)
		fun getFollowing(): [FriendStatus]{ 
			return self.following.values
		}
		
		access(all)
		fun setName(_ val: String){ 
			self.name = val
		}
		
		access(all)
		fun setAvatar(_ val: String){ 
			self.avatar = val
		}
		
		access(all)
		fun setDescription(_ val: String){ 
			self.description = val
		}
		
		access(all)
		fun setTags(_ val: [String]){ 
			self.tags = val
		}
		
		access(all)
		fun removeCollection(_ val: String){ 
			self.collections.remove(key: val)
		}
		
		//TODO: make this the identifier of the collection type rather then the name. just remove the name
		access(all)
		fun addCollection(_ val: ResourceCollection){ 
			self.collections[val.name] = val
		}
		
		access(all)
		fun getCollections(): [ResourceCollection]{ 
			return self.collections.values
		}
		
		access(all)
		fun follow(_ address: Address, tags: [String]){ 
			let friendProfile = Profile.find(address)
			let owner = (self.owner!).address
			let status = FriendStatus(follower: owner, following: address, tags: tags)
			self.following[address] = status
			friendProfile.internal_addFollower(status)
			emit Follow(follower: owner, following: address, tags: tags)
		}
		
		access(all)
		fun unfollow(_ address: Address){ 
			self.following.remove(key: address)
			Profile.find(address).internal_removeFollower((self.owner!).address)
			emit Unfollow(follower: (self.owner!).address, unfollowing: address)
		}
		
		access(contract)
		fun internal_addFollower(_ val: FriendStatus){ 
			if self.allowStoringFollowers && !self.bans.containsKey(val.follower){ 
				self.followers[val.follower] = val
			}
		}
		
		access(contract)
		fun internal_removeFollower(_ address: Address){ 
			if self.followers.containsKey(address){ 
				self.followers.remove(key: address)
			}
		}
		
		access(all)
		view fun getSupportedVaultTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedVaultType(type: Type): Bool{ 
			panic("implement me")
		}
	}
	
	access(all)
	fun find(_ address: Address): &{Profile.Public}{ 
		return (getAccount(address).capabilities.get<&{Profile.Public}>(Profile.publicPath)!)
			.borrow()!
	}
	
	access(all)
	fun createUser(
		name: String,
		description: String,
		allowStoringFollowers: Bool,
		tags: [
			String
		]
	): @Profile.User{ 
		pre{ 
			Profile.verifyTags(tags: tags, tagLength: 10, tagSize: 3):
				"cannot have more then 3 tags of length 10"
			name.length <= 16:
				"Name must be 16 or less characters"
			description.length <= 255:
				"Descriptions must be 255 or less characters"
		}
		return <-create Profile.User(
			name: name,
			description: description,
			allowStoringFollowers: allowStoringFollowers,
			tags: tags
		)
	}
	
	access(all)
	view fun verifyTags(tags: [String], tagLength: Int, tagSize: Int): Bool{ 
		if tags.length > tagSize{ 
			return false
		}
		for t in tags{ 
			if t.length > tagLength{ 
				return false
			}
		}
		return true
	}
	
	init(){ 
		self.publicPath = /public/VersusUserProfile
		self.storagePath = /storage/VersusUserProfile
	}
}
