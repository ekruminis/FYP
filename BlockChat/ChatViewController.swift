//  Created by Edvinas Kruminis on 21/12/2018.
//  Copyright © 2018 Edvinas Kruminis. All rights reserved.
//

import UIKit
import Firebase
import CommonCrypto
import Alamofire
import CoreData

class ChatViewController: UIViewController {
    
    var usr:String? = MessengerViewController().chosenUser
	var recipient:String? = ""
	var dbRef = Database.database().reference()
	var sessionID:String? = ""
	var myName:String? = ""
	var recpPublicKey:String? = ""
	var key:String? = ""
	
    @IBOutlet weak var changeKeyButton: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var SendingButton: UIButton!
	
	// Generate new key, and send a new block with that information
    @IBAction func changeKey(_ sender: Any) {
		// Disable button interaction
        changeKeyButton.isUserInteractionEnabled = false
        
		self.key = self.genKey()
		
		let pk = self.getPublicKey()
		let sndKey = self.encryptRSA(key: self.key!, publicKey: pk)
		
		let pkData = Data(base64Encoded: self.recpPublicKey!)
		let recpPK = self.createKeyFromData(key: pkData!) as! SecKey
		let recpKey = self.encryptRSA(key: self.key!, publicKey: recpPK)
		
		let signature = getSignature(text: self.key!)
		
		let changeKey = self.block.updateBlock(snd: Auth.auth().currentUser?.uid ?? "snd error", recp: self.recipient ?? "recp error", aesKey1: sndKey, aesKey2: recpKey, sign: signature)
		
		msgList.text.append("**YOU CHANGED THE SESSION KEY**\n")
		self.block.chain.append(changeKey)
		
		// Re-enable button interaction after 5 sec
        Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { _ in
            self.changeKeyButton.isUserInteractionEnabled = true
            print("can press again")
        })
    }
	
	// Go back to main menu
    @IBAction func goBack(_ sender: Any) {
		let storyboard = UIStoryboard(name: "Messenger", bundle: nil)
		let vc = storyboard.instantiateViewController(withIdentifier: "Messenger") as UIViewController
		self.present(vc, animated: true, completion: nil)
    }
	
	// Check what messages are available
    @IBAction func refresh(_ sender: Any) {
        refreshButton.isUserInteractionEnabled = false
        msgList.text = ""
        retrieveBlockchain()
		
		// Re-enable button interaction after 3 sec
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { _ in
            self.refreshButton.isUserInteractionEnabled = true
            print("can press again")
        })
    }
    
    @IBOutlet weak var msgType: UITextField!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var msgList: UITextView!
	
	// Allow keyboard press of send/go/return to call 'send' button
    @IBAction func kbSend(_ sender: Any) {
        sendButton(self)
    }
	
	var block = BlockChain()
	
	// Create new block with the message and send/mine it
    @IBAction func sendButton(_ sender: Any) {
		if(msgType.hasText) {
			let txt = self.msgType.text
			//let start = DispatchTime.now()
			let pkData = Data(base64Encoded: self.recpPublicKey!)
			let pk = self.createKeyFromData(key: pkData!) as! SecKey
			
			let encryptedMessage = self.encryptAES(key: self.key!, text: txt!)
			let encryptedKey = self.encryptRSA(key: self.key!, publicKey: pk)
			
			let signature = getSignature(text: txt!)
			
			// disable user interaction of buttons/prevent new messages being sent until finished sending block
			self.refreshButton.isUserInteractionEnabled = false
			self.changeKeyButton.isUserInteractionEnabled = false
			self.msgType.isUserInteractionEnabled = false
			self.SendingButton.isUserInteractionEnabled = false
			self.msgType.text = "Sending . . . "
			
			// call mining on background thread so user device is not blocked
			DispatchQueue.global(qos: .background).async {
				self.block.addBlock(snd: Auth.auth().currentUser?.uid ?? "snd error", recp: self.recipient ?? "recp error",
								msg: encryptedMessage, aesKey: encryptedKey, sign: signature)
				self.resetTextField()
				//let end = DispatchTime.now()
				//print("Time taken: \(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000)")
		}
		}
    }
	
	// Generate signature based on the message
	func getSignature(text:String) -> String {
		let myPrivateKey:SecKey = getPrivateKey()
		
		let hashedMessage = text.data(using: .utf8)?.hashSHA256() as! CFData

		var error: Unmanaged<CFError>?
		guard let signature = SecKeyCreateSignature(myPrivateKey,
													.rsaSignatureMessagePKCS1v15SHA512,
													hashedMessage as CFData,
													&error) as Data? else {
														print("Error: \(error!.takeRetainedValue() as Error)")
														return ""
		}
		let dataSignature:Data = signature as! Data
		return dataSignature.base64EncodedString()
	}
	
	// Check if signature is correct
	func verifySignature(sign:String, msg:String) -> Bool {
		print("message: \(msg)")
		let signature:CFData = Data(base64Encoded: sign) as! CFData
		
		let hashedMessage = msg.data(using: .utf8)?.hashSHA256() as! CFData
		
		let dataSignature:Data = signature as! Data
		print("signature: \(dataSignature.base64EncodedString())")
		let pkData = Data(base64Encoded: self.recpPublicKey!)
		let recpPK = self.createKeyFromData(key: pkData!) as! SecKey
		
		var error: Unmanaged<CFError>?
		guard SecKeyVerifySignature(recpPK,
									.rsaSignatureMessagePKCS1v15SHA512,
									hashedMessage as CFData,
									signature as CFData,
									&error) else {
										return false
		}
		return true
	}
	
	// Re-enable user interaction
	func resetTextField() {
		DispatchQueue.main.async {
			self.msgType.text = ""
			self.refreshButton.isUserInteractionEnabled = true
			self.changeKeyButton.isUserInteractionEnabled = true
			self.msgType.isUserInteractionEnabled = true
			self.SendingButton.isUserInteractionEnabled = true
		}
	}
	
	// Decrypt blocks and show valid messages
	func showMessages(valid:Bool, msg:String) {
		if(valid) {
			// Messages I sent
			if(block.lastBlock().sender == Auth.auth().currentUser?.uid && block.lastBlock().recipient == recipient) {
				let message = decryptAES(key: key!, text: block.lastBlock().data)
				msgList.text.append("Me: \(message)\n")
			}
			// Messages I received
			else if(block.lastBlock().sender == recipient && block.lastBlock().recipient == Auth.auth().currentUser?.uid) {
				key = decryptRSA(cipherText: block.lastBlock().key)
				let message = decryptAES(key: key!, text: block.lastBlock().data)
				if(self.verifySignature(sign: block.lastBlock().signature, msg: message)) {
					print("signature verified")
					msgList.text.append("\(userLabel.text!): \(message)\n")
				}
				else {
					print("Could not verify signature!")
				}
			}
		}
			// block not valid, inform user
		else {
			if(block.lastBlock().sender == Auth.auth().currentUser?.uid && block.lastBlock().recipient == recipient) {
				let message = decryptAES(key: key!, text: msg)
				msgList.text.append("**Your msg (\(message)) was not official**\n")
			}
		}
		
		// scroll to bottom so newest messages are easily seen
		let bottom = NSMakeRange(msgList.text?.count ?? 0, 0)
		msgList.scrollRangeToVisible(bottom)
	}
	
	// AES encryption (AES-256, HMAC+SHA256, PBKDF2)
	// https://github.com/RNCryptor/RNCryptor
	func encryptAES(key: String, text: String) -> String {
		let encText = RNCryptor.encrypt(data: text.data(using: String.Encoding.utf8)!, withPassword: key)
		return encText.base64EncodedString()
	}
	
	// AES decryption (AES-256, HMAC+SHA256, PBKDF2)
	// https://github.com/RNCryptor/RNCryptor
	func decryptAES(key:String, text: String) -> String {
		do {
			let dataText = Data.init(base64Encoded: text)!
			let decText = try RNCryptor.decrypt(data: dataText, withPassword: key)
			
			return String(data: decText, encoding: .utf8)!
		} catch let error {
			print("Error encountered: \n\(error)\n")
		}
		return "err"
	}
	
	// Get users private key
	func getPrivateKey() -> SecKey {
		var error: Unmanaged<CFError>?
		let tag = ("kruminis.BlockChat."+(Auth.auth().currentUser?.uid)!).data(using: .utf8)!
		let getquery: [String: Any] = [kSecClass as String: kSecClassKey,
									   kSecAttrApplicationTag as String: tag,
									   kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
									   kSecReturnRef as String: true]
		
		var item: CFTypeRef?
		let status = SecItemCopyMatching(getquery as CFDictionary, &item)
		guard status == errSecSuccess else { print("error"); return error as! SecKey }
		return item as! SecKey
	}
	
	// Get users public key
	func getPublicKey() -> SecKey {
		let pk = getPrivateKey()
		let publicKey = SecKeyCopyPublicKey(pk)
		return publicKey!
	}
	
	// Create SecKey object from Data given
	func createKeyFromData(key: Data) -> SecKey {
		var error: Unmanaged<CFError>?
		let options: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
									  kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
									  kSecAttrKeySizeInBits as String : 2048]
		
		guard let key = SecKeyCreateWithData(key as CFData,
											 options as CFDictionary,
											 &error) else {print("error create error");fatalError()}
		
		return key
	}
	
	// Generate new AES Key
	func genKey() -> String {
		var bytes = [UInt8](repeating: 0, count: 24)
		let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
		var key:String = ""
		if status == errSecSuccess {
			let data = Data(bytes: bytes)
			key = data.base64EncodedString()
		}
		return key
	}
	
	// RSA2048 Encryption
	func encryptRSA(key: String, publicKey: SecKey) -> String {
		let key = Data(base64Encoded: key)
		
		let publicKey = publicKey
		
		var error: Unmanaged<CFError>?
		guard let cipherText = SecKeyCreateEncryptedData(publicKey,
														 .rsaEncryptionPKCS1,
														 key as! CFData,
														 &error) as Data? else {
															print("error encrypting"); fatalError()
		}
		
		let cipher = cipherText as Data?
		let baseCipher = cipher!.base64EncodedString()
		return baseCipher
	}
	
	// RSA2048 Decryption
	func decryptRSA(cipherText: String) -> String {
		var error: Unmanaged<CFError>?
		let privateKey = self.getPrivateKey()
		let cipher = Data(base64Encoded: cipherText)
		
		guard let clearText = SecKeyCreateDecryptedData(privateKey,
														.rsaEncryptionPKCS1,
														cipher! as CFData,
														&error) as Data? else {
															print("error decrypting"); fatalError()
		}
		
		let decipher = clearText as Data?
		let text = decipher!.base64EncodedString()
		return text
	}
	
	// Add new Core Data object
	func saveCoreData(link:String, date:String, with:String) {
		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return}
		let context = appDelegate.persistentContainer.viewContext
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		let entity = NSEntityDescription.entity(forEntityName: "Blockchain", in: context)!
		let blockchain = NSManagedObject(entity: entity, insertInto: context)
		blockchain.setValue(link, forKeyPath: "link")
		blockchain.setValue(date, forKeyPath: "date")
		blockchain.setValue(with, forKeyPath: "conversationWith")
		do {
			try context.save()
		} catch let error as NSError {
			print("error saving")
		}
	}
	
	var allBlocks:Dictionary<String, Block> = [:]
	
	// Get all blocks from database
	func retrieveBlockchain() {
		self.block.chain = []
		self.key = self.genKey()
		if(sessionID == "" && recipient != "" && myName != "") {
			// If new session, generate genesis block and start session
			dbRef.child("sessions").child(Auth.auth().currentUser!.uid).child(usr!).observeSingleEvent(of: .value, with: { snapshot in
				if !snapshot.exists() {
					let pk = self.getPublicKey()
					let sndKey = self.encryptRSA(key: self.key!, publicKey: pk)
					
					let pkData = Data(base64Encoded: self.recpPublicKey!)
					let recpPK = self.createKeyFromData(key: pkData!) as! SecKey
					let recpKey = self.encryptRSA(key: self.key!, publicKey: recpPK)
					
					let signature = self.getSignature(text: self.key!)
					
					let genesis = self.block.genesisBlock(snd: Auth.auth().currentUser?.uid ?? "snd error", recp: self.recipient ?? "recp error", aesKey1: sndKey, aesKey2: recpKey, sign: signature)
					self.dbRef.child("sessions").child(self.recipient!).child(self.myName!).setValue(genesis.0)
					self.dbRef.child("sessions").child(Auth.auth().currentUser!.uid).child(self.usr!).setValue(genesis.0)
					self.sessionID = genesis.0
					self.block.chain.append(genesis.1)
				}
				else {
					if let userDict = snapshot.value as? Dictionary<String, AnyObject> {
						self.sessionID = userDict[self.usr!] as! String
					}
				}
			})
		}
		else {
			// Session is already active, so go to all Swarm links, parse data and create new blocks
			self.dbRef.child("blockchain").child(sessionID!).queryOrderedByKey().observeSingleEvent(of: .value, with: { snapshot in
				if let blockDict = snapshot.value as? Dictionary<String, String> {
					// Order dictionary by date sent
					let orderedDict = blockDict.keys.sorted().map { ($0, blockDict[$0]!) }
					
					// Setup concurrency to ensure that all addresses were parsed before continuing
					let group = DispatchGroup()
					for i in 0..<orderedDict.count {
						// Start semaphore blocking
						group.enter()
                        self.msgList.text = ("Loading...")
						print(i)
						// Send HTTP GET request
						Alamofire.request("https://swarm-gateways.net/bzz:/"+orderedDict[i].1).responseJSON {
							response in
							
							if let json = response.result.value as? [String: Any] {
								let index = json["index"] as! Int
								let date = json["date"] as! Double
								let prev = json["previousHash"] as! String
								let nonce = json["nonce"] as! Int
								let dif = json["difficultyLevel"] as! Int
								let sender = json["sender"] as! String
								let recp = json["recipient"] as! String
								let data = json["data"] as! String
								let key = json["key"] as! String
								let sID = json["sessionID"] as! String
								let signature = json["signature"] as! String
								
								// Save to core data
								self.saveCoreData(link: ("https://swarm-gateways.net/bzz:/"+orderedDict[i].1), date: String(date), with: self.usr!)
								
								let b = Block(index: index, date: date, previousHash: prev, nonce: nonce, difficultyLevel: dif, sender: sender, recipient: recp, data: data, key: key, sessionID: sID, signature: signature)
								
								self.allBlocks[String(date).replacingOccurrences(of: ".", with: "")] = b
								// Stop semaphore blocking
								group.leave()
							}
						}
					}
					// All addresses successfully finished calling
					group.notify(queue: DispatchQueue.main) {
						print("all info data has been received")
                        self.msgList.text = ("")
						self.addConversations()
					}
				}
			})
		}
	}
	
	// Check block content
	func addConversations() {
		// Sort dictionary by date sent
		let sortedBlockchain = self.allBlocks.keys.sorted().map { ($0, self.allBlocks[$0]!) }
		for i in 0..<sortedBlockchain.count {
			// If block hash is valid..
			if(self.block.verifyBlock(b: sortedBlockchain[i].1) == true) {
				print("Block no.\(i)")
				// If genesis block, accept and parse AES key information
				if(sortedBlockchain[i].1.previousHash == "GENESIS") {
					self.block.chain.append(sortedBlockchain[i].1)
					print("GENESIS added")
					// parse info
					if(sortedBlockchain[i].1.sender == Auth.auth().currentUser!.uid) {
						let encKey = sortedBlockchain[i].1.data
						self.key = self.decryptRSA(cipherText: encKey)
					}
					else if(sortedBlockchain[i].1.recipient == Auth.auth().currentUser!.uid) {
						let encKey = sortedBlockchain[i].1.key
						self.key = self.decryptRSA(cipherText: encKey)
						// verify signature
						if(self.verifySignature(sign: block.lastBlock().signature, msg: self.key!)) {
							print("signature verified")
						}
						else {
							print("Could not verify signature!")
							self.key = ""
						}
					}
				}
					// If difficulty level is 1, we know this is a block trying to change AES key
				else if(sortedBlockchain[i].1.difficultyLevel == 1) {
					print("key change!!")
					self.block.chain.append(sortedBlockchain[i].1)
					// parse info
					if(sortedBlockchain[i].1.sender == Auth.auth().currentUser!.uid) {
						let encKey = sortedBlockchain[i].1.data
						self.key = self.decryptRSA(cipherText: encKey)
					}
					else if(sortedBlockchain[i].1.recipient == Auth.auth().currentUser!.uid) {
						let encKey = sortedBlockchain[i].1.key
						self.key = self.decryptRSA(cipherText: encKey)
						// verify signature
						if(self.verifySignature(sign: block.lastBlock().signature, msg: self.key!)) {
							print("signature verified")
						}
						else {
							print("Could not verify signature!")
							self.key = ""
						}
					}
				}
					// Else, normal messaging block
				else {
					print("normal msg")
					let prevHash = self.block.lastBlock().encryptSHA256()
					
					// check if this block is referencing the last active blockchain block
					if(sortedBlockchain[i].1.previousHash == prevHash) {
						self.block.chain.append(sortedBlockchain[i].1)
						print("new block added")
						self.showMessages(valid: true, msg: "")
					}
						// this block is referencing wrong block in its prevHash
					else {
						print("block rejected")
						print("\(sortedBlockchain[i].1.previousHash) vs. \(prevHash)")
						self.showMessages(valid: false, msg: sortedBlockchain[i].1.data)
					}
				}
			}
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
        userLabel.adjustsFontSizeToFitWidth = true
        userLabel.textAlignment = .center
		userLabel.text = usr
		
		// get recipients public key
		let databaseReference = Database.database().reference(withPath: "public_keys")
		databaseReference.child(self.recipient!).observeSingleEvent(of: .value, with: { snapshot in
			if !snapshot.exists() { print("error");return }
			self.recpPublicKey = snapshot.value as! String
		})

		self.retrieveBlockchain()
    }
}
