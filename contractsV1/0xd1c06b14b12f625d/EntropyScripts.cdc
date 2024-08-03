access(all)
contract EntropyScripts{ 
	
	// EntropyScripts Contract Events
	access(all)
	event ContractInitialized()
	
	// Paths
	access(all)
	let AdminStoragePath: StoragePath
	
	// -----------------------------------------------------------------------
	// EntropyScripts contract-level fields.
	// -----------------------------------------------------------------------
	access(self)
	var scripts: @{UInt64: Script}
	
	access(self)
	var scriptPaths:{ String: StoragePath}
	
	// The ID that is used to create Scripts
	// Every time a a new resource is created, an ID is assigned 
	// to the new Resource's ID and then is incremented by 1.
	access(all)
	var nextScriptID: UInt64
	
	access(all)
	resource Script{ 
		// The Script resource stores the signature art inside the Entropy account
		access(all)
		let name: String
		
		access(all)
		var signature: String
		
		//		pub let path: String
		init(name: String, signature: String){ 
			self.name = name
			//			self.path = path
			self.signature = signature
		}
		
		access(contract)
		fun addToString(string: String){ 
			self.signature = self.signature.concat(string)
		}
	}
	
	access(all)
	resource Admin{ 
		
		// Create a new Script
		access(all)
		fun createScript(scriptName: String, scriptSignature: String){ 
			// Create script resource
			var newScript <- create Script(name: scriptName, signature: scriptSignature)
			
			// Save the script path inside the contract's dictionary
			EntropyScripts.scriptPaths[scriptName] = StoragePath(
					identifier: "Entropy_".concat(scriptName)
				)
			// Save resource with the script inside the Entropy account 
			// with a unique script name TO DO 
			EntropyScripts.account.storage.save(
				<-newScript,
				to: EntropyScripts.scriptPaths[scriptName]!
			)
		}
		
		access(all)
		fun addToString(scriptName: String, string: String){ 
			let script =
				EntropyScripts.account.storage.borrow<&EntropyScripts.Script>(
					from: EntropyScripts.scriptPaths[scriptName]!
				)!
			script.addToString(string: string)
		}
		
		// create a new Administrator resource
		access(all)
		fun createAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(all)
	fun getScript(scriptName: String): String{ 
		let script =
			EntropyScripts.account.storage.borrow<&EntropyScripts.Script>(
				from: EntropyScripts.scriptPaths[scriptName]!
			)!
		return script.signature
	}
	
	init(){ 
		self.scripts <-{} 
		self.scriptPaths ={} 
		self.nextScriptID = 0
		self.AdminStoragePath = /storage/EntropyScriptsAdmin
		
		// Create a Administrator resource and save it to storage
		let administrator <- create Admin()
		self.account.storage.save(<-administrator, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
