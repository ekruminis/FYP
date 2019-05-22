//  Created by Edvinas Kruminis on 01/01/2019.
//  Copyright © 2019 Edvinas Kruminis. All rights reserved.
//

import UIKit
import Firebase

class ContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
	
    @IBOutlet weak var contactsTable: UITableView!
	
	var dict:NSDictionary = [:]
	var myName:String? = ""
	
	var uids:[String] = []
	var sessionDict:NSDictionary = [:]
	
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
	
	var friends:[String] = []
	
	// Table view setup
    func tableView(_ contactsTable: UITableView, numberOfRowsInSection section: Int) -> Int {
		return friends.count
	}
	
	// Table view setup
	func tableView(_ contactsTable: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var cell:UITableViewCell = self.contactsTable.dequeueReusableCell(withIdentifier: "cell3") as! UITableViewCell
		
		cell.textLabel?.text = self.friends[indexPath.item]
		cell.textLabel?.textColor = UIColor.white
		cell.accessoryType = .disclosureIndicator
		
		return cell
	}
	
	var chosenUser:String! = "blank"
	
	// Table view selection action
	func tableView(_ contactsTable: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.chosenUser = friends[indexPath.item]
		
		let sb = UIStoryboard(name: "Chat", bundle: nil)
		let vc = sb.instantiateViewController(
			withIdentifier: "Chat") as? ChatViewController
		vc?.usr = self.chosenUser!
		vc?.myName = self.myName!
		vc?.recipient = (self.dict.value(forKey: self.chosenUser!) as! String)
		vc?.sessionID = (self.sessionDict.value(forKey: self.chosenUser!) as? String ?? "")
		self.present(vc as! UIViewController, animated: true, completion: nil)
	}
	
	// Table view edit action
	func tableView(_ searchTable: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
		
		// remove from friends list
		let remove = UITableViewRowAction(style: .default, title: "Remove") {action, index in
			Database.database().reference(withPath: "friends/\(Auth.auth().currentUser!.uid)").child(self.friends[editActionsForRowAt.item]).removeValue()
			self.friends.remove(at: editActionsForRowAt.item)
			self.contactsTable.deleteRows(at: [editActionsForRowAt], with: UITableView.RowAnimation.left)
			self.contactsTable?.reloadData()
		}
		remove.backgroundColor = .red
		
		// start chat
		let chat = UITableViewRowAction(style: .default, title: "Chat") { action, index in
			var chosenUser = self.friends[editActionsForRowAt.item]
			let sb = UIStoryboard(name: "Chat", bundle: nil)
			let vc = sb.instantiateViewController(
				withIdentifier: "Chat") as?                                         ChatViewController
			vc?.usr = chosenUser
			vc?.myName = self.myName!
			vc?.recipient = (self.dict.value(forKey: self.chosenUser!) as! String)
			vc?.sessionID = (self.sessionDict.value(forKey: self.chosenUser!) as? String ?? "")
			self.present(vc as! UIViewController, animated: true, completion: nil)
		}
		chat.backgroundColor = .blue
		
		return [chat,remove]
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Get list of friends
		var databaseReference = Database.database().reference(withPath: "friends/\(Auth.auth().currentUser!.uid)")
		databaseReference.observeSingleEvent(of: .value, with: { snapshot in
			if !snapshot.exists() { return }
			if let userDict = snapshot.value as? Dictionary<String, AnyObject> {
				self.friends = [String](userDict.keys)
			}
			self.contactsTable?.reloadData()
		})
		
		// Get users
		databaseReference = Database.database().reference(withPath: "usernames")
		databaseReference.observeSingleEvent(of: .value, with: { snapshot in
			if !snapshot.exists() { return }
			if let userDict = snapshot.value as? NSDictionary {
				self.dict = userDict
				self.myName = userDict.allKeys(for: Auth.auth().currentUser!.uid).first as! String
			}
		})
		
		// Get active sessions
	Database.database().reference().child("sessions").child(Auth.auth().currentUser!.uid).observeSingleEvent(of: .value, with: { snapshot in
			if !snapshot.exists() { return }
			if let userDict = snapshot.value as? NSDictionary {
				self.sessionDict = userDict
			}
		})
	}
}
