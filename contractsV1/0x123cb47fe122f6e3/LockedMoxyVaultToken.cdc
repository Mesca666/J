import MoxyVaultToken from "./MoxyVaultToken.cdc"

import LinearRelease from "./LinearRelease.cdc"

import MoxyData from "./MoxyData.cdc"

access(all)
contract LockedMoxyVaultToken{ 
	access(all)
	var totalSupply: UFix64
	
	/// LockedTokensWithdrawn
	///
	/// The event that is emitted when locked tokens are withdrawn from a Vault
	/// due to an MV to MOX convert request
	access(all)
	event LockedTokensWithdrawn(amount: UFix64, from: Address?)
	
	access(all)
	struct FixedBalance{ 
		// This is the schedule of how the tokens will be unlock
		access(all)
		var schedule: LinearRelease.LinearSchedule
		
		// This is the amount that is remaining to unlock
		access(all)
		var remaining: UFix64
		
		access(all)
		fun getBalanceRemaining(): UFix64{ 
			return self.remaining
		}
		
		access(all)
		fun unlockAmounts(): UFix64{ 
			if self.remaining == 0.0{ 
				return 0.0
			}
			var amount = self.schedule.getDailyAmountToPay()
			
			// Check for remainings
			if amount > self.remaining{ 
				log("Negative amount :".concat(amount.toString()).concat(" self.remaining ").concat(self.remaining.toString()))
				amount = self.remaining
			}
			if self.remaining - amount < 0.001{ 
				// Set the residual
				amount = self.remaining
			}
			self.remaining = self.remaining - amount
			self.schedule.updateLastReleaseDate()
			return amount
		}
		
		init(schedule: LinearRelease.LinearSchedule, remaining: UFix64){ 
			self.schedule = schedule
			self.remaining = remaining
		}
	}
	
	access(all)
	resource LockedVault: Receiver, Balance{ 
		access(contract)
		var lockedBalances:{ UFix64: UFix64}
		
		access(contract)
		var lockedFixedBalances: [FixedBalance]
		
		access(contract)
		var vault: @MoxyVaultToken.Vault
		
		access(all)
		fun getBalance(): UFix64{ 
			return self.vault.balance
		}
		
		access(all)
		fun getDailyBalanceFor(timestamp: UFix64): UFix64?{ 
			return self.vault.getDailyBalanceFor(timestamp: timestamp)
		}
		
		access(all)
		fun getDailyBalancesChangesUpTo(timestamp: UFix64):{ UFix64: UFix64}{ 
			return self.vault.getDailyBalancesChangesUpTo(timestamp: timestamp)
		}
		
		access(all)
		fun isValutBalanceOk(): Bool{ 
			var locked = 0.0
			var lockedFixed = 0.0
			locked = self.sumLockedBalances()
			lockedFixed = self.sumLockedFixedBalances()
			let total = locked + lockedFixed
			let diff: Fix64 = Fix64(self.vault.balance) - Fix64(total)
			return self.vault.balance == total
		}
		
		access(all)
		fun deposit(from: @MoxyVaultToken.Vault){ 
			self.depositFor(from: <-from, time: getCurrentBlock().timestamp)
		}
		
		access(all)
		fun depositFor(from: @MoxyVaultToken.Vault, time: UFix64){ 
			let amount = from.balance
			self.vault.depositAmount(from: <-from)
			if self.lockedBalances[time] == nil{ 
				self.lockedBalances[time] = 0.0
			}
			self.lockedBalances[time] = self.lockedBalances[time]! + amount
			LockedMoxyVaultToken.totalSupply = LockedMoxyVaultToken.totalSupply + amount
		}
		
		access(all)
		fun depositFromFixedSchedule(from: @MoxyVaultToken.Vault, schedule: LinearRelease.LinearSchedule){ 
			let total = from.balance
			self.vault.depositAmount(from: <-from)
			let time = getCurrentBlock().timestamp
			let fixedBalance = FixedBalance(schedule: schedule, remaining: total)
			self.lockedFixedBalances.append(fixedBalance)
			LockedMoxyVaultToken.totalSupply = LockedMoxyVaultToken.totalSupply + total
		}
		
		access(all)
		fun depositFromSchedule(from: @MoxyVaultToken.Vault, schedule:{ UFix64: UFix64}){ 
			let total = from.balance
			self.vault.depositAmount(from: <-from)
			let ti = getCurrentBlock().timestamp
			
			// Merge schedules with existing lockedBalances
			for time in schedule.keys{ 
				if self.lockedBalances[time] == nil{ 
					self.lockedBalances[time] = 0.0
				}
				self.lockedBalances[time] = self.lockedBalances[time]! + schedule[time]!
			}
			LockedMoxyVaultToken.totalSupply = LockedMoxyVaultToken.totalSupply + total
		}
		
		access(all)
		fun sumLockedBalances(): UFix64{ 
			var total = 0.0
			for value in self.lockedBalances.values{ 
				total = total + value
			}
			return total
		}
		
		access(all)
		fun sumLockedFixedBalances(): UFix64{ 
			var total = 0.0
			for fixed in self.lockedFixedBalances{ 
				total = total + fixed.getBalanceRemaining()
			}
			return total
		}
		
		// Withdraws the tokens that are available to unlock
		access(all)
		fun withdrawUnlocked(): @MoxyVaultToken.Vault{ 
			let temp = self.lockedBalances
			var total = 0.0
			let dict = self.getUnlockBalancesFor(days: 0.0)
			for key in dict.keys{ 
				let value = dict[key]!
				let amount = self.lockedBalances[key]!
				self.lockedBalances.remove(key: key)
				total = total + amount
			}
			
			// Unlock fixed amounts
			var totalFixed = 0.0
			var i = 0
			while i < self.lockedFixedBalances.length{ 
				let amount = self.lockedFixedBalances[i].unlockAmounts()
				totalFixed = totalFixed + amount
				i = i + 1
			}
			total = total + totalFixed
			LockedMoxyVaultToken.totalSupply = LockedMoxyVaultToken.totalSupply - total
			if self.vault.balance < total{ 
				let diff = total - self.vault.balance
				if diff > 1.0{ 
					panic("Error vault does not have enough balance")
				}
				total = self.vault.balance
			}
			if self.vault.balance > total{ 
				let diff = self.vault.balance - total
				if diff < 0.001{ 
					// Set the residual on vault
					total = self.vault.balance
				}
			}
			let vault <- self.vault.withdrawAmount(amount: total) as! @MoxyVaultToken.Vault
			return <-vault
		}
		
		access(all)
		fun getTotalLockedBalance(): UFix64{ 
			return self.vault.balance
		}
		
		access(all)
		fun getTotalToUnlockBalanceFor(days: UFix64): UFix64{ 
			// Returns the amount that will be unlocked in the next few days
			var total = 0.0
			var timestamp = getCurrentBlock().timestamp + days * 86400.0
			for key in self.lockedBalances.keys{ 
				if key < timestamp{ 
					let value = self.lockedBalances[key]!
					total = total + value
				}
			}
			return total
		}
		
		access(all)
		fun getUnlockBalancesFor(days: UFix64):{ UFix64: UFix64}{ 
			// Returns a dictionary with the amounts that will be unlocked in the next few days
			var dict:{ UFix64: UFix64} ={} 
			var timestamp = getCurrentBlock().timestamp + days * 86400.0
			for key in self.lockedBalances.keys{ 
				if key < timestamp{ 
					dict[key] = self.lockedBalances[key]!
				}
			}
			return dict
		}
		
		init(vault: @MoxyVaultToken.Vault){ 
			self.lockedBalances ={} 
			self.lockedFixedBalances = []
			self.vault <- vault
		}
	}
	
	access(all)
	resource interface Receiver{ 
		
		/// deposit takes a Vault and deposits it into the implementing resource type
		///
		access(all)
		fun deposit(from: @MoxyVaultToken.Vault)
		
		access(all)
		fun depositFor(from: @MoxyVaultToken.Vault, time: UFix64)
		
		access(all)
		fun depositFromSchedule(from: @MoxyVaultToken.Vault, schedule:{ UFix64: UFix64})
		
		access(all)
		fun depositFromFixedSchedule(
			from: @MoxyVaultToken.Vault,
			schedule: LinearRelease.LinearSchedule
		)
	}
	
	access(all)
	resource interface Balance{ 
		
		/// The total balance of a vault
		///
		access(all)
		fun getBalance(): UFix64
		
		access(all)
		fun getDailyBalanceFor(timestamp: UFix64): UFix64?
		
		access(all)
		fun getDailyBalancesChangesUpTo(timestamp: UFix64):{ UFix64: UFix64}
		
		access(all)
		fun getTotalToUnlockBalanceFor(days: UFix64): UFix64
		
		access(all)
		fun getTotalLockedBalance(): UFix64
	}
	
	access(all)
	fun createLockedVault(vault: @MoxyVaultToken.Vault): @LockedVault{ 
		return <-create LockedVault(vault: <-vault)
	}
	
	init(){ 
		self.totalSupply = 0.0
	}
}
