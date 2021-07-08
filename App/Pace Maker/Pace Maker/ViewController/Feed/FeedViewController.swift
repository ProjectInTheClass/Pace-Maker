//
//  FeedViewController.swift
//  Pace Maker
//
//  Created by 전연지 on 2021/05/06.
//

import UIKit
import Firebase

class FeedViewController: UIViewController {
 
    @IBOutlet weak var feedCollectionView: UICollectionView!
    
    //Load Logs Of Friends
    private var logsOfUser: [DataSnapshot] = []
    private var index = 0
    
    func loadLogsOfUser(){
        let refer = realtimeReference.reference(withPath: "log")
        let logOrderByDate = refer.queryOrdered(byChild: "date")
        logOrderByDate.observeSingleEvent(of: .value) {snapshot in
            for child in snapshot.children.allObjects as! [DataSnapshot]{
                let val = child.childSnapshot(forPath: "runner").value as! String
                if val == user?.UID{
                    self.logsOfUser.append(child)
                    let distanceTmp = child.childSnapshot(forPath: "distance").value as! Float64
                    user?.runningDistance += distanceTmp
                    let timeTmp = child.childSnapshot(forPath: "time").value as! Float64
                    user?.runningTime += timeTmp
                }
                
            }
            self.logsOfUser.reverse()
            self.feedCollectionView.reloadData()
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    
        feedCollectionView.delegate = self
        feedCollectionView.dataSource = self
        feedCollectionView.register(UINib(nibName: "FeedCell", bundle: nil), forCellWithReuseIdentifier: "FeedCell")
        
        feedCollectionView.register(UINib(nibName: "CollectionReusableView", bundle: nil), forSupplementaryViewOfKind:UICollectionView.elementKindSectionHeader, withReuseIdentifier: "FeedHeader")
        
        loadLogsOfUser()
        setupFlowLayout()
    }
    
    
    
    private func setupFlowLayout() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets.zero
        flowLayout.minimumInteritemSpacing = 2
        flowLayout.minimumLineSpacing = 2
        
        
        flowLayout.headerReferenceSize = CGSize(width: self.feedCollectionView.frame.size.width, height: 262)
        
        let width = UIScreen.main.bounds.size.width / 3 - 2
        flowLayout.itemSize = CGSize(width: width, height: width)
        self.feedCollectionView.collectionViewLayout = flowLayout
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.feedCollectionView.reloadData()
    }

}

extension FeedViewController: UICollectionViewDelegate, UICollectionViewDataSource, HeaderViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.logsOfUser.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedCell", for: indexPath) as? FeedCell else {
            return UICollectionViewCell()
        }
        
        let tmpLog = logsOfUser[indexPath.row]
        let key = tmpLog.key
        getLogImage(imgview: cell.imageView, logName: "\(key)")
        cell.configure()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let width: CGFloat = collectionView.frame.width
        let height: CGFloat = 20
        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FeedHeader", for: indexPath) as! CollectionReusableView
            // do any programmatic customization, if any, here
            header.configure()
            header.delegate = self
            return header
        }
        fatalError("Unexpected kind")
    }

    func touchEditButton() {
        performSegue(withIdentifier: "Setting", sender: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "contentsSegue", sender: self)
    }
    
}
