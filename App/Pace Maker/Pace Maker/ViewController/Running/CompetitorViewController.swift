//
//  CompetitorViewController.swift
//  Pace Maker
//
//  Created by Kyungho on 2021/05/27.
//

import UIKit

enum Category: String {
    case myself = "myself"
    case celebrities = "celebrities"
    case friends = "friends"
}

class CompetitorViewController: UIViewController {
    
    let categoryWithIndex: [Category] = [Category.myself,Category.celebrities,Category.friends]
    var followers: [String:[String:String]] = [Category.myself.rawValue:[user!.name:user!.UID] ,
                                            Category.celebrities.rawValue:[:],
                                            Category.friends.rawValue:[:]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadDatabase()
        // Do any additional setup after loading the view.
    }
    
    func loadDatabase() {
//        print(user?.friends)
        loadFriends()
    }
    
    func loadFriends(){
        guard let friends = user?.friends else {return}
        followers[Category.friends.rawValue]?.removeAll()
        for friend in friends {
            followers[Category.friends.rawValue]?["name"] = friend
        }
    }

}

// DATA SOURCE
extension CompetitorViewController :UITableViewDataSource, UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return followers[categoryWithIndex[section].rawValue]!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "follower",for: indexPath)
        
        let _ = Array(followers.values)[indexPath.section]
        
        cell.textLabel!.text = "auaicn"
        return cell

    }
    
    // ABOUT SECTION
    func numberOfSections(in tableView: UITableView) -> Int {
        return followers.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(categoryWithIndex[section].rawValue)"
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let sectionCount: Int = followers[categoryWithIndex[section].rawValue]?.count ?? 0
        return "\(sectionCount) 명"
    }
}
