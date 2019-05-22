//
//  SettingsViewController.swift
//  BlockChat
//
//  Created by Edvinas Kruminis on 01/01/2019.
//  Copyright © 2019 Edvinas Kruminis. All rights reserved.
//

import UIKit
import Firebase
import CoreData

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
	
    @IBOutlet weak var settingsTable: UITableView!
	
	var dbRef = Database.database().reference()
	var email:String = ""
	var username:String = ""
	var userID:String = ""
	
	// Log out
    @IBAction func logOut(_ sender: Any) {
		let firebaseAuth = Auth.auth()
		do {
			try firebaseAuth.signOut()
			print ("LOGGED OUT!")
		} catch let signOutError as NSError {
			print ("Error signing out: %@", signOutError)
		}
		let storyboard = UIStoryboard(name: "Login", bundle: nil)
		let vc = storyboard.instantiateViewController(withIdentifier: "Login") as UIViewController
		self.present(vc, animated: true, completion: nil)
    }
	
	// All possible options
    var options:[String] = ["Change Password", "Change Email", "Delete Account", "Contact support", "Get My Public Key", "Get My Private Key", "Get My Messages", "Delete Stored Messages"]
	
	// Table view setup
    func tableView(_ settingsTable: UITableView, numberOfRowsInSection section: Int) -> Int {
		return options.count
	}
	
	// Table view setup
	func tableView(_ settingsTable: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var cell:UITableViewCell = self.settingsTable.dequeueReusableCell(withIdentifier: "cell") as! UITableViewCell
		
		cell.textLabel?.text = options[indexPath.item]
		cell.textLabel?.textColor = UIColor.white
		return cell
	}
	
	// Table view selection action
	func tableView(_ settingsTable: UITableView, didSelectRowAt indexPath: IndexPath) {
		// change password
		if(indexPath.item == 0) {
			changePassword()
		}
		// change email
		else if(indexPath.item == 1) {
			changeEmail()
		}
		// delete account
		else if(indexPath.item == 2) {
			deleteAccount()
		}
		// contact support
		else if(indexPath.item == 3) {
			let alert = UIAlertController(title: "Contact Support", message: "If you would like to get in contact with the developer, please email e.kruminis@lancaster.ac.uk", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
			self.present(alert, animated: true)
		}
		// get public key
		else if(indexPath.item == 4) {
			getPublicKey()
		}
		//get private key
		else if(indexPath.item == 5) {
			getPrivateKey()
		}
		//get blocks
		else if(indexPath.item == 6) {
			getCoreData()
		}
		//delete block storage
		else if(indexPath.item == 7) {
			deleteCoreData()
		}
	}
	
	// Save users core data into their clipboard
	func getCoreData() {
		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return}
		let context = appDelegate.persistentContainer.viewContext
		let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Blockchain")
		
		do {
			let result = try context.fetch(fetch)
			// reset clipboard
			UIPasteboard.general.string = ""
			
			// get all items
			for data in result as! [NSManagedObject] {
				UIPasteboard.general.string? += """
				---
				with: \(data.value(forKey: "conversationWith") as! String)
				at: \(data.value(forKey: "date") as! String)
				link: \(data.value(forKey: "link") as! String)
				---
				"""
			}
			
		} catch {
			print("error getting data")
			let alert = UIAlertController(title: "Error", message: "There was an error in getting data from your device", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
			self.present(alert, animated: true)
			return
		}
		let alert = UIAlertController(title: "Success", message: "All your messages have been stored in the clipboard", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
		self.present(alert, animated: true)
	}
	
	// Delete currently stored core data
	func deleteCoreData() {
		let alert = UIAlertController(title: "**WARNING**", message: "Messages will still persist on the Swarm network, and access to them may still be available either on our databases or on the devices of the people you were conversing with. Only the storage of these messages on your device are deleted.\n\nAre you sure you want to delete your stored messages? This action is irreversible.", preferredStyle: .alert)
		
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		
		alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { [weak alert] (_) in
			
		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return}
		let context = appDelegate.persistentContainer.viewContext
		let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Blockchain")
		
		do
		{
			let items = try context.fetch(fetch)
			
			// delete all items
			if(items.count != 0) {
				for i in 0...items.count-1 {
					let del = items[i] as! NSManagedObject
					context.delete(del)
				}
				
				do {
					try context.save()
					let alert = UIAlertController(title: "Success", message: "All stored messages on your device were deleted", preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
					self.present(alert, animated: true)
				}
				catch {
					print(error)
					let alert = UIAlertController(title: "Error", message: "There was an error in deleting data from your device", preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
					self.present(alert, animated: true)
					return
				}
			}
			else {
				let alert = UIAlertController(title: "Error", message: "No messages are stored in your device", preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
				self.present(alert, animated: true)
				return
			}
		}
		catch {
			print(error)
			let alert = UIAlertController(title: "Error", message: "There was an error in deleting data from your device", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
			self.present(alert, animated: true)
			return
		}
		}))
		self.present(alert, animated: true)
	}
	
	// Save users public key into their clipboard
	func getPublicKey() {
		var error: Unmanaged<CFError>?
		let tag = ("kruminis.BlockChat."+(Auth.auth().currentUser?.uid)!).data(using: .utf8)!
		let getquery: [String: Any] = [kSecClass as String: kSecClassKey,
									   kSecAttrApplicationTag as String: tag,
									   kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
									   kSecReturnRef as String: true] // data for string, ref for key
		
		var item: CFTypeRef?
		let status = SecItemCopyMatching(getquery as CFDictionary, &item)
		guard status == errSecSuccess else {
			let alert = UIAlertController(title: "Error", message: "The key for this user was not found on this device", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
			self.present(alert, animated: true)
			return }
		
		let publicKey = SecKeyCopyPublicKey(item as! SecKey)
		let kk = SecKeyCopyExternalRepresentation(publicKey!, &error)
		let data2 = kk as Data?
		let base64PublicKey = data2!.base64EncodedString()
		
		UIPasteboard.general.string = base64PublicKey
		let alert = UIAlertController(title: "Public Key", message: "Your public key is now stored in your clipboard.", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
		self.present(alert, animated: true)
	}
	
	// Save users private key into their clipboard
	func getPrivateKey() {
		var error: Unmanaged<CFError>?
		let tag = ("kruminis.BlockChat."+(Auth.auth().currentUser?.uid)!).data(using: .utf8)!
		let getquery: [String: Any] = [kSecClass as String: kSecClassKey,
									   kSecAttrApplicationTag as String: tag,
									   kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
									   kSecReturnRef as String: true] // data for string, ref for key
		
		var item: CFTypeRef?
		
		let status = SecItemCopyMatching(getquery as CFDictionary, &item)
		guard status == errSecSuccess else {
			let alert = UIAlertController(title: "Error", message: "The key for this user was not found on this device", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
			self.present(alert, animated: true)
			return }
		
		let privateKey = SecKeyCopyExternalRepresentation(item as! SecKey, &error)
		let data = privateKey as Data?
		let base64PrivateKey = data!.base64EncodedString()
		UIPasteboard.general.string = base64PrivateKey
		
		let alert = UIAlertController(title: "Private Key", message: "**WARNING** KEEP THIS INFORMATION SECURE\n\nYour private key is now stored in your clipboard.", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
		self.present(alert, animated: true)
	}
	
	// Change user email
	func changeEmail() {
		let alert = UIAlertController(title: "Change Email", message: "Please enter your new email", preferredStyle: .alert)
		
		alert.addTextField(configurationHandler: {(textField) in
			textField.text = ""
		})
		
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak alert] (_) in
			let newEmail = alert?.textFields![0].text as! String
			
			Auth.auth().currentUser?.updateEmail(to: newEmail) { (error) in
				if error == nil && self.userID != "" {
				
					let alert = UIAlertController(title: "Success!", message: "Your email has been successfully updated!", preferredStyle: .alert)
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
	
	// Change user password
	func changePassword() {
		let alert = UIAlertController(title: "Change Password", message: "Please enter your new password", preferredStyle: .alert)
		
		alert.addTextField(configurationHandler: {(textField) in
			textField.text = ""
		})
		alert.addTextField(configurationHandler: {(textField) in
			textField.text = ""
		})
		
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak alert] (_) in
			let newPass1 = alert?.textFields![0].text as! String
			let newPass2 = alert?.textFields![1].text as! String
			
			// check if passwords match, and are >6 char in length, have at least one uppercase letter and one number
			if(newPass1 == newPass2) {
				let uppercase = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
				let numbers = CharacterSet(charactersIn: "0123456789")
				
				if(newPass1.count < 6 || newPass1.rangeOfCharacter(from: uppercase) == nil || newPass1.rangeOfCharacter(from: numbers) == nil) {
					let alert = UIAlertController(title: "Password error", message: "Password should contain at least 6 characters, at least one uppercase latter, and at least one number", preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
					self.present(alert, animated: true)
					return
				}
				
			Auth.auth().currentUser?.updatePassword(to: newPass1) { (error) in
				if error == nil {
					let alert = UIAlertController(title: "Success!", message: "Your password has been successfully updated!", preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
					self.present(alert, animated: true)
				} else {
					print(error!.localizedDescription)
					let alert = UIAlertController(title: "Error", message: "Something went wrong! Please try again and make sure the info was right", preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
					self.present(alert, animated: true)
				}
			}
			}
			else{
				let alert = UIAlertController(title: "Error", message: "The password fields do not match!", preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
				self.present(alert, animated: true)
			}
		}))
		self.present(alert, animated: true)
	}
	
	// Delete current account and delete their database information (blockchain and sessions remain)
	func deleteAccount() {
		let alert = UIAlertController(title: "**WARNING**", message: "Are you sure you want to delete your account? This action is irreversible", preferredStyle: .alert)
		
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		
		alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { [weak alert] (_) in
			
			self.deleteKey()
			
			Auth.auth().currentUser?.delete(completion: { (error) in if error == nil {
			
			self.dbRef.child("usernames").child(self.username).removeValue()
			self.dbRef.child("friends").child(self.username).removeValue()
			self.dbRef.child("public_keys").child(self.username).removeValue()
			
			let alert = UIAlertController(title: "Success", message: "Your account has been successfully deleted", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {_ in
				let storyboard = UIStoryboard(name: "Login", bundle: nil)
				let vc = storyboard.instantiateViewController(withIdentifier: "Login") as UIViewController
				self.present(vc, animated: true, completion: nil)
			}))
			self.present(alert, animated: true)
			do {
				try Auth.auth().signOut()
				print ("LOGGED OUT!")
			} catch let signOutError as NSError {
				print ("Error signing out: %@", signOutError)
			}
			
			} else {
				print(error!.localizedDescription)
				let alert = UIAlertController(title: "Error", message: "Something went wrong! Please try again", preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
				self.present(alert, animated: true)
			}
		})
		}))
		self.present(alert, animated: true)
	}
	
	// Delete the key of the current user
	func deleteKey() {
		let tag = ("kruminis.BlockChat." + (Auth.auth().currentUser?.uid)!).data(using: .utf8)!
		
		let query: [String: Any] = [kSecClass as String: kSecClassKey,
									kSecAttrApplicationTag as String: tag,
									kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
									kSecReturnRef as String: true]
		
		print("DELETING KEY")
		print(SecItemDelete(query as CFDictionary))
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.email = Auth.auth().currentUser!.email!
		self.userID = Auth.auth().currentUser!.uid
		
		var databaseReference = Database.database().reference(withPath: "usernames")
		
		// Get users
		databaseReference.observeSingleEvent(of: .value, with: { snapshot in
			if !snapshot.exists() { return }
			if let userDict = snapshot.value as? NSDictionary {
				userDict
				self.username = userDict.allKeys(for: self.userID)[0] as! String
			}
			self.settingsTable.reloadData()
		})
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
