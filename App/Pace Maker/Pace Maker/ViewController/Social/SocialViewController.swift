//
//  SocialViewController.swift
//  Pace Maker
//
//  Created by 성준오 on 2021/06/03.
//

import UIKit
import Firebase

class SocialViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate{

    
    @IBOutlet weak var socialCollectionView: UICollectionView!
    
    var logOfFriends: [DataSnapshot] = []
    
    let today = Date()
    
    var index = 0

    override func viewDidLoad() {
        super.viewDidLoad()
//        self.loadLogsOfFriends()
        self.setupFlowLayout()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadLogsOfFriends()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let user = user else { return 0 }
        return self.logOfFriends.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "socialCell", for: indexPath) as?
                    socialFeedCell else {
                return UICollectionViewCell()
            }

        cell.contentView.layer.masksToBounds = true
        cell.roundView.layer.masksToBounds = true
        
        let tmpLog = logOfFriends[indexPath.row]
        let key = tmpLog.key
        getLogImage(imgview: cell.imgView, logName: "\(key)")
        let nick = tmpLog.childSnapshot(forPath: "nick").value as! String
        let date = tmpLog.childSnapshot(forPath: "date").value as! String
        var distance = tmpLog.childSnapshot(forPath: "distance").value as! Float64
        distance = round(distance * 100) / 100
        var time = tmpLog.childSnapshot(forPath: "time").value as! Float64
        time = round(time * 100) / 100
        
        cell.userLabel.textAlignment = .center
        cell.userLabel.numberOfLines = 1
        cell.userLabel.text = "\(nick)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = dateFormatter.date(from: date)!
        let daysCount = self.days(from: startDate)
        
        cell.dateLabel.textAlignment = .center
        cell.dateLabel.numberOfLines = 1
        cell.dateLabel.text = "\(daysCount)일 전"
        
        cell.infoLog.numberOfLines = 1
        cell.infoLog.text = " \(distance) (km) / \(time) (seconds)"
        return cell
    }
    
    func days(from date:Date) -> Int{
        return Calendar.current.dateComponents([.day], from:date, to:self.today).day! + 1
    }
    
    private func setupFlowLayout() {
        let flowLayout = UICollectionViewFlowLayout()
        let width = socialCollectionView.bounds.width
        let space = width / 20
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: space, bottom: 0, right: 0)
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        
        let halfWidth = width
        flowLayout.itemSize = CGSize(width: halfWidth, height: halfWidth * 1.2)
        self.socialCollectionView.collectionViewLayout = flowLayout
    }
    
    //Load Logs Of Friends
    private func loadLogsOfFriends(){
        guard let user = user else { return }
        
        let refer = realtimeReference.reference(withPath: "log")
        let logOrderByDate = refer.queryOrdered(byChild: "date").queryLimited(toLast: 30)
        logOrderByDate.observeSingleEvent(of: .value) {snapshot in
            self.logOfFriends.removeAll()
            for child in snapshot.children.allObjects as! [DataSnapshot]{
                let val = child.childSnapshot(forPath: "runner").value as! String
                if ((user.friends.contains(val)) != nil) {
                    self.logOfFriends.append(child)
                }
            }
            // self.logOfFriends.reverse()
            self.socialCollectionView.reloadData()
        }
        
    }
    
}

class socialFeedCell: UICollectionViewCell{
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var infoLog: UILabel!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var roundView: RoundedView!
}


