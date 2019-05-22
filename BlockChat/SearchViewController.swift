//  Created by Edvinas Kruminis on 30/12/2018.
//  Copyright © 2018 Edvinas Kruminis. All rights reserved.
//

import UIKit
import Firebase

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
	
    @IBOutlet weak var searchTable: UITableView!
    
	var userNames:[String] = []
	var searchingUsers:[String] = []
	
	var uids:[String] = []
	var dict:NSDictionary = [:]
	var myName:String? = ""
	var sessionDict:NSDictionary = [:]
	
	// Table view setup
	func tableView(_ searchTable: UITableView, numberOfRowsInSection section: Int) -> Int {
		return searchingUsers.count
	}
	
	// Table view setup
    func tableView(_ searchTable: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var cell:UITableViewCell = self.searchTable.dequeueReusableCell(withIdentifier: "cell2") as! UITableViewCell
		
		cell.textLabel?.text = searchingUsers[indexPath.item]
		cell.textLabel?.textColor = UIColor.white
        cell.accessoryType = .disclosureIndicator
		return cell
	}
	
	// Table view edit action
	func tableView(_ searchTable: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
		
		// add user as a friend
		let add = UITableViewRowAction(style: .default, title: "add") {action, index in
			Database.database().reference(withPath: "usernames").observeSingleEvent(of: .value, with: { snapshot in
				if !snapshot.exists() { return }
				if let userDict = snapshot.value as? Dictionary<String, AnyObject> {
					var uid = userDict[self.searchingUsers[editActionsForRowAt.item]] as? String
					Database.database().reference(withPath: "friends/\(Auth.auth().currentUser!.uid)").child(self.searchingUsers[editActionsForRowAt.item]).setValue(uid)
				}
			})
		}
		add.backgroundColor = .green
		
		// start chat with user
        let chat = UITableViewRowAction(style: .default, title: "Chat") { action, index in
			self.chosenUser = self.searchingUsers[editActionsForRowAt.item]
			let sb = UIStoryboard(name: "Chat", bundle: nil)
			let vc = sb.instantiateViewController(
				withIdentifier: "Chat") as?                                         ChatViewController
			vc?.usr = self.chosenUser!
			vc?.myName = self.myName!
			vc?.recipient = (self.dict.value(forKey: self.chosenUser!) as! String)
			print((self.sessionDict.value(forKey: self.chosenUser!) as? String ?? ""))
			vc?.sessionID = (self.sessionDict.value(forKey: self.chosenUser!) as? String ?? "")
			self.present(vc as! UIViewController, animated: true, completion: nil)
        }
        chat.backgroundColor = .blue
        
        return [chat,add]
    }
    
    var chosenUser:String! = "blank"
	
	// Table view selection action
	func tableView(_ searchTable: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.chosenUser = searchingUsers[indexPath.item]
		
		let sb = UIStoryboard(name: "Chat", bundle: nil)
		let vc = sb.instantiateViewController(
			withIdentifier: "Chat") as?                                         ChatViewController
		vc?.usr = self.chosenUser!
		vc?.myName = self.myName!
		vc?.recipient = (self.dict.value(forKey: self.chosenUser!) as! String)
		vc?.sessionID = (self.sessionDict.value(forKey: self.chosenUser!) as? String ?? "")
		print((self.sessionDict.value(forKey: self.chosenUser!) as? String ?? ""))
		self.present(vc as! UIViewController, animated: true, completion: nil)
	}
	
	// Search for users
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		searchingUsers = userNames.filter({(text: String) -> Bool in
			return text.range(of: searchText, options: .caseInsensitive) != nil
		})
		self.searchTable.reloadData()
	}
	
    @IBOutlet weak var searchBar: UISearchBar!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// Get all users
		var databaseReference = Database.database().reference(withPath: "usernames")
		databaseReference.observeSingleEvent(of: .value, with: { snapshot in
			if !snapshot.exists() { return }
			if let userDict = snapshot.value as? Dictionary<String, AnyObject> {
				self.userNames = [String](userDict.keys)
				self.dict = userDict as NSDictionary
				self.myName = (userDict as NSDictionary).allKeys(for: Auth.auth().currentUser!.uid).first as! String
			}
			self.searchTable?.reloadData()
		})
		
		// Get active conversations
	Database.database().reference().child("sessions").child(Auth.auth().currentUser!.uid).observeSingleEvent(of: .value, with: { snapshot in
			if !snapshot.exists() { return }
			if let userDict = snapshot.value as? NSDictionary {
				self.sessionDict = userDict
			}
    	})
	}
}
