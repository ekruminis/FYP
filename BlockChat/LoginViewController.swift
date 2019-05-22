//  Created by Edvinas Kruminis on 10/11/2018.
//  Copyright © 2018 Edvinas Kruminis. All rights reserved.
//

import UIKit
import Firebase
import CommonCrypto
import Alamofire
import Security
import CoreData

class LoginViewController: UIViewController {
	
	var databaseReference = Database.database().reference()
	
	// Ask Firebase to set password reset link
    @IBAction func resetPW(_ sender: Any) {
        let alert = UIAlertController(title: "I Forgot my Password", message: "Please enter your email down below", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: {(textField) in
            textField.text = ""
        })
		
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { [weak alert] (_) in
			let toSend = alert?.textFields![0].text as! String
			Auth.auth().sendPasswordReset(withEmail: toSend) { (error) in
				if error == nil {
					let alert = UIAlertController(title: "Reset successful!", message: "Your password reset link has been sent out! Please check your email inbox and follow the instructions.", preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
					self.present(alert, animated: true)
				} else {
					print(error!.localizedDescription)
					let alert = UIAlertController(title: "Error", message: "Something went wrong! Please try again and make sure the info was right", preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
					self.present(alert, animated: true)
				}
			}
		}))
		self.present(alert, animated: true)
    }
    
    @IBOutlet weak var logEmailField: UITextField!
    @IBOutlet weak var logPassField: UITextField!
	
	// Login with credentials
    @IBAction func logButton(_ sender: Any) {
        guard let email = logEmailField.text else {return}
        guard let pw = logPassField.text else {return}
        
        Auth.auth().signIn(withEmail: email, password: pw) { (user, error) in
            if error == nil && user != nil {
				
				let storyboard = UIStoryboard(name: "Messenger", bundle: nil)
				let vc = storyboard.instantiateViewController(withIdentifier: "Messenger") as UIViewController
				self.present(vc, animated: true, completion: nil)

            } else {
                print(error!.localizedDescription)
				let alert = UIAlertController(title: "Error", message: error!.localizedDescription, preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
				self.present(alert, animated: true)
            }
        }
    }
	
	// Delete user key
	func deleteKey() {
		let tag = ("kruminis.BlockChat." + (Auth.auth().currentUser?.uid)!).data(using: .utf8)!
		
		let query: [String: Any] = [kSecClass as String: kSecClassKey,
									kSecAttrApplicationTag as String: tag,
									kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
									kSecReturnRef as String: true]
		
		print("DELETING KEY")
		print(SecItemDelete(query as CFDictionary))
	}
    
    @IBOutlet weak var regUserField: UITextField!
    @IBOutlet weak var regEmailField: UITextField!
    @IBOutlet weak var regPassField: UITextField!
	
	// Register new user
    @IBAction func regButton(_ sender: Any) {
		
		// check if username length is >4
		if((regUserField.text?.count)! < 4) {
			let alert = UIAlertController(title: "Username error", message: "Username should be at least 4 characters long!", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
			self.present(alert, animated: true)
			return
		}
		let uppercase = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
		let numbers = CharacterSet(charactersIn: "0123456789")
		
		// check if password is >6 char in length, have at least one uppercase letter and one number
		if((regPassField.text?.count)! < 6 || regPassField.text?.rangeOfCharacter(from: uppercase) == nil || regPassField.text?.rangeOfCharacter(from: numbers) == nil) {
			let alert = UIAlertController(title: "Password error", message: "Password should contain at least 6 characters, at least one uppercase latter, and at least one number", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
			self.present(alert, animated: true)
			return
		}
	
        guard let username = regUserField.text else {return}
        guard let email = regEmailField.text else {return}
        guard let pw = regPassField.text else {return}
		
		// create new user, and update database with their information
		_ = self.databaseReference.child("usernames").child(username).observe(.value, with: {(snapshot:DataSnapshot) in
			if(!snapshot.exists())
			{
				Auth.auth().createUser(withEmail: email, password: pw) { (user, error) in
					if error == nil && user != nil {
						let userID = Auth.auth().currentUser!.uid
						
							self.databaseReference.child("usernames").child(username.lowercased()).setValue(userID)
						
						let pk = self.createKey()
						self.databaseReference.child("public_keys").child(userID).setValue(pk)
						
						print("User created!")
						let alert = UIAlertController(title: "User created", message: "You have successful registered! Now go back and login with you credentials", preferredStyle: .alert)
						alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
						self.present(alert, animated: true)
						
					} else {
						print(error!.localizedDescription)
						let alert = UIAlertController(title: "Error", message: error!.localizedDescription, preferredStyle: .alert)
						alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
						self.present(alert, animated: true)
					}
				}
			}
			else
			{
				print("username already in use!")
				let alert = UIAlertController(title: "Username taken", message: "Someone is already using that username! Please try a different one", preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
				self.present(alert, animated: true)
			}
		})
    }
	var users:[String] = []
	
	// Create new RSA key and return the public key
	func createKey() -> String {
		let tag = ("kruminis.BlockChat."+(Auth.auth().currentUser?.uid)!).data(using: .utf8)!
	
		let attributes: [String: Any] =
			[kSecAttrKeyType as String:            kSecAttrKeyTypeRSA,
			 kSecAttrKeySizeInBits as String:      2048,
			 kSecPrivateKeyAttrs as String:
				[kSecAttrIsPermanent as String:    true,
				 kSecAttrApplicationTag as String: tag]
		]
		
		
		var error: Unmanaged<CFError>?
		guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else  {
			print("Error: \(error!.takeRetainedValue() as Error)")
			return ""
		}
		
		let publicKey = SecKeyCopyPublicKey(privateKey)
		let temp = SecKeyCopyExternalRepresentation(publicKey!, &error)

		let pkData = temp as Data?
		let base64PublicKey = pkData!.base64EncodedString()
		return base64PublicKey
	}
	
    override func viewDidLoad() {
		super.viewDidLoad()
	}
}
