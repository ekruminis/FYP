//  Created by Edvinas Kruminis on 31/10/2018.
//  Copyright © 2018 Edvinas Kruminis. All rights reserved.
//

import Foundation
import UIKit
import CommonCrypto
import Alamofire
import Firebase

class BlockChain {
	var chain: [Block] = []
	
	// Create genesis block
	func genesisBlock(snd: String, recp: String, aesKey1: String, aesKey2: String, sign: String) -> (String, Block) {
		let sID = genID()
		var block = Block(index: 0,
						  date: Date().timeIntervalSince1970,
						  previousHash: "GENESIS",
						  nonce: 0,
						  difficultyLevel: 2,
						  sender: snd,
						  recipient: recp,
						  data: aesKey1,
						  key: aesKey2,
						  sessionID: sID,
						  signature: sign)
		block = mine(b: block)
		return (sID, block)
	}
	
	// Generate random session ID
	func genID() -> String {
		var bytes = [UInt8](repeating: 0, count: 24)
		let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
		var id:String = ""
		if status == errSecSuccess {
			let data = Data(bytes: bytes)
			id = data.base64EncodedString()
		}
		return id
	}
	
	// Create a new block
	func addBlock(snd: String, recp: String, msg: String, aesKey: String, sign: String) {
		let block = Block(index: chain.count,
						  date: Date().timeIntervalSince1970,
						  previousHash: lastBlock().encryptSHA256(),
						  nonce: 0,
						  difficultyLevel: 3,
						  sender: snd,
						  recipient: recp,
						  data: msg,
						  key: aesKey,
						  sessionID: lastBlock().sessionID,
						  signature: sign);
		mine(b: block)
	}
	
	// Update the session key
	func updateBlock(snd: String, recp: String, aesKey1: String, aesKey2: String, sign: String) -> Block {
		var block = Block(index: chain.count,
							  date: Date().timeIntervalSince1970,
							  previousHash: lastBlock().encryptSHA256(),
							  nonce: 0,
							  difficultyLevel: 1,
							  sender: snd,
							  recipient: recp,
							  data: aesKey1,
							  key: aesKey2,
							  sessionID: lastBlock().sessionID,
							  signature: sign)
		block = mine(b: block)
		return block
	}
	
	// Return last block
	func lastBlock() -> Block {
		guard let lastBlock = chain.last else {
			fatalError()
		}
		return lastBlock
	}
	
	// Check if block hash is valid
	func verifyBlock(b: Block) -> Bool {
		let mb = b
		let difficulty = String(repeating: "0", count: mb.difficultyLevel)
		if(mb.encryptSHA256().hasPrefix(difficulty) == true){
			return true
		}
		else {
			return false
		}
	}
	
	// Mine the block, upload it to Swarm and save the address in the database
	func mine(b: Block) -> Block {
		
		var mb = b
		let difficulty = String(repeating: "0", count: mb.difficultyLevel)
		
		while(mb.encryptSHA256().hasPrefix(difficulty) == false) {
			mb.nonce = mb.nonce + 1
		}
		
		let jdata = try! JSONEncoder().encode(mb)
		var hash:String = ""
		let url = URL(string: "https://swarm-gateways.net/bzz:/")!
		var request = URLRequest(url: url)
		request.httpMethod = HTTPMethod.post.rawValue
		request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
		request.httpBody = jdata
		Alamofire.request(request).responseString {
			response in
			hash = response.result.value!
				Database.database().reference().child("blockchain").child(mb.sessionID).child(String(mb.date).replacingOccurrences(of: ".", with: "")).setValue(hash)
		}
		return mb
	}
}
