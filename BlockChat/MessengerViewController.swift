//  Created by Edvinas Kruminis on 11/11/2018.
//  Copyright © 2018 Edvinas Kruminis. All rights reserved.
//

import UIKit
import Firebase
import Alamofire

class MessengerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	
    @IBOutlet weak var home: UIButton!
    @IBOutlet weak var contacts: UIButton!
    @IBOutlet weak var settings: UIButton!
    
    var userNames:[String] = []
	var uids:[String] = []
	var dict:NSDictionary = [:]
	var myName:String? = ""
	var sessionDict:NSDictionary = [:]
	
	var dbRef = Database.database().reference()
	
	// Table view setup
    func tableView(_ chatTable: UITableView, numberOfRowsInSection section: Int) -> Int {
		return userNames.count
	}
	
	// Table view setup
	func tableView(_ chatTable: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var cell:UITableViewCell = self.chatTable.dequeueReusableCell(withIdentifier: "cell") as! UITableViewCell
		
		cell.textLabel?.text = self.userNames[indexPath.item]
		cell.textLabel?.textColor = UIColor.white
		return cell
	}
	
    @IBOutlet weak var chatTable: UITableView!
	
	var chosenUser:String! = "blank"
	
	// Table view selection action
	func tableView(_ chatTable: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.chosenUser = userNames[indexPath.item]
		
		let sb = UIStoryboard(name: "Chat", bundle: nil)
		let vc = sb.instantiateViewController(
			withIdentifier: "Chat") as? ChatViewController
		vc?.usr = self.chosenUser!
		vc?.myName = self.myName!
		vc?.recipient = (self.dict.value(forKey: self.chosenUser!) as! String)
		vc?.sessionID = (self.sessionDict.value(forKey: self.chosenUser!) as! String)
		self.present(vc as! UIViewController, animated: true, completion: nil)
	}
	
	// Log out
    @IBAction func logOutButton(_ sender: Any) {
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
	
	// Return active conversations of this user
	func getChat() {
		self.dbRef.child("sessions").child(Auth.auth().currentUser!.uid).observeSingleEvent(of: .value, with: { snapshot in
			if !snapshot.exists() { return }
			if let userDict = snapshot.value as? NSDictionary {
				self.userNames = userDict.allKeys as! [String]
				self.sessionDict = userDict
				//Add this key to userID array
			}
			self.chatTable?.reloadData()
		})
	}
	
    override func viewDidLoad() {
		super.viewDidLoad()
		
		// Get the names of the users
		var databaseReference = Database.database().reference(withPath: "usernames")
		databaseReference.observeSingleEvent(of: .value, with: { snapshot in
			if !snapshot.exists() { return }
			if let userDict = snapshot.value as? NSDictionary {
				self.dict = userDict
				self.myName = (userDict.allKeys(for: Auth.auth().currentUser!.uid).first as! String)
			}
			self.getChat()
		})
	}
}
