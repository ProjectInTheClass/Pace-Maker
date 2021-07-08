//
//  UserSearchTableTableViewController.swift
//  Pace Maker
//
//  Created by 성준오 on 2021/06/04.
//
import Firebase
import UIKit

class UserSearchTableTableViewController: UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate {

    @IBOutlet var userTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    var userCandidate: [DataSnapshot] = []
    //private let sections: [String] = ["New", "Friends"]

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        
        userTableView.delegate = self
        userTableView.dataSource = self
    }
    
    func getProfileImage(imgview: UIImageView, id: String){
        let imageUrl = storageUrlBase + "profiles/" + id + ".jpg"
        storage.reference(forURL: imageUrl).downloadURL { (url, error) in
            if let _ = error {
                //let image = UIImage()
                //imgview.image = image
            }
            else{
                let data = NSData(contentsOf: url!)
                let image = UIImage(data: data! as Data)
                imgview.image = image
                
            }
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print(searchText)
        
        self.userCandidate = []
        
        let input = searchText.lowercased()
        let refer = realtimeReference.reference(withPath: "user")
        let users = refer.queryOrdered(byChild: "nick")
        users.observe(.value, with: {snapshot in
            for child in snapshot.children.allObjects as! [DataSnapshot]{
                let nickName = child.childSnapshot(forPath: "nick").value as! String
                let realName = child.childSnapshot(forPath: "name").value as! String
                
                let nick = nickName.lowercased()
                let name = realName.lowercased()
                
                if (nick.contains(input)) || (name.contains(input)){
                    self.userCandidate.append(child)
                }
            }
            print(self.userCandidate.count)
            self.userTableView.reloadData()
        })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    // Returns the title of the section.
    //func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { return sections[section] }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        //print(self.userCandidate.count)
        return self.userCandidate.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UsersCell", for: indexPath) as! UsersCell

        let candidate =  self.userCandidate[indexPath.row]
        
        let key = candidate.key
        
        self.getProfileImage(imgview: cell.imgView, id: key)
        
        let nick = candidate.childSnapshot(forPath: "nick").value as! String
        let name = candidate.childSnapshot(forPath: "name").value as! String
        
        let txt = "\(nick) (\(name))"
        
        cell.userInfoLabel.text = txt
        
        return cell
    }

    @IBAction func followUser(_ sender: Any) {
        print("button clicked")
    }
}
