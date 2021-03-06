//
//  RouteSelectViewController.swift
//  Pace Maker
//
//  Created by Kyungho on 2021/05/27.
//

import UIKit
import Firebase

class RouteSelectViewController: UIViewController {
    
    var routes: [Log] = []
    var routesBySelf: [Log] = []
    var routesOthers: [Log] = []
    
    var refreshControl = UIRefreshControl()
    
    @IBOutlet weak var encourageMessage: UILabel!
    @IBOutlet weak var bestRecordLabel: UILabel!
    @IBOutlet weak var latestRecordLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBar()
        setTableView()
        loadLogs()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // loadLogs()
    }
    
    func setNavigationBar(){
        self.navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    func setTableView(){
        tableView.delegate = self
        tableView.dataSource = self
        setPullToRefresh()
    }
    
    func setPullToRefresh(){
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl) // not required when using UITableViewController
    }
    
    @objc func refresh(_ sender: AnyObject) {
        // Code to refresh table view
        self.tableView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    func loadLogs(){
        guard let user = user else { return }
        
        let logReference = realtimeReference.reference(withPath: "log")
        logReference.queryOrdered(byChild: "date")
            .observeSingleEvent(of: .value) { snapshot in
                let snapshot = snapshot.value as? [String : AnyObject] ?? [:]
                 print("LOGS snapshot.count",snapshot.count)
                
                self.routes.removeAll()
                for (logId,log) in snapshot {
                    
                    let date: String = log["date"] as! String
                    let distance: Double = log["distance"] as! Double
                    let route: String = log["route"] as! String
                    let time: Double = log["time"] as! Double
                    let nickname: String = log["nick"] as! String
                    
                    let runnerId: String = log["runner"] as! String
                    
                    let fetchedLog = Log(dateString: date, distanceInKilometer: distance, routeSavedPath: route, runnerUID: runnerId, nickname: nickname, timeSpentInSeconds: time)
                    
                    if runnerId == user.UID {
                        self.routesBySelf.append(fetchedLog)
                    } else {
                        self.routesOthers.append(fetchedLog)
                    }
                }
                self.routesBySelf.sort() {$0.dateString > $1.dateString }
                self.routesOthers.sort() {$0.dateString > $1.dateString }
                self.routesOthers = self.routesOthers.uniqueFilter()
                self.updateUI()
            }
    }
    
    func updateUI() {
        tableView.reloadData()
        
        if routesBySelf.count != 0 {
            // ?????? ??????
            guard let paceInSeconds = routesBySelf.max(by: { lhs, rhs in
                lhs.pace < rhs.pace
            })?.pace else { return }
            
            bestRecordLabel.text = "km ??? \(paceInSeconds / 60) ??? \(paceInSeconds % 60) ???"
            
            // ?????? ??????
            guard let latestRecordPaceInSeconds = routesBySelf.first?.pace else { return }
            latestRecordLabel.text = "km ??? \(latestRecordPaceInSeconds / 60) ??? \(latestRecordPaceInSeconds % 60) ???"
            
        }else {
            bestRecordLabel.text = "- : --"
            latestRecordLabel.text = "- : --"
        }
    }
    
    /// ?????????????????? ???????????? ?????????, ????????? ??? ?????? ?????? ???????????????, ?????? ???????????? ?????? ????????? ??????????????? ?????????.
    /// RouteDetailViewController ??? log ??? ?????????????????? ????????????.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nextViewController = segue.destination as? RouteDetailViewController{
            if let indexPath = tableView.indexPathForSelectedRow {
                // table view cell ??????
                let selectedRoute = indexPath.section == 1 ? routesBySelf[indexPath.row] : routesOthers[indexPath.row]
                nextViewController.log = selectedRoute
            }else {
                // ??? ????????????-???????????? ?????? ??????????????? ?????? (table view ??? ??????)
                nextViewController.log = routesBySelf.max(by: { lhs, rhs in
                    lhs.pace < rhs.pace
                })
            }
        }
    }
}

extension RouteSelectViewController : UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = 0
        if !routesBySelf.isEmpty {
            numberOfSections += 1
        }
        if !routesOthers.isEmpty {
            numberOfSections += 1
        }
        return numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return routesBySelf.count
        }else {
            return routesOthers.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "?????? ??????"
        }else {
            return "???????????? ??????"
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let footer = view as? UITableViewHeaderFooterView else { return }
        footer.textLabel?.textAlignment = .right
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "??? \(routesBySelf.count) ?????? ?????????"
        }else {
            return "??? \(routesOthers.count) ?????? ?????????"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RoutesTableViewCell",for: indexPath)
        
        if indexPath.section == 0 {
            let route = routesBySelf[indexPath.row]
            
            cell.textLabel?.text = "\(route.dateString) ?????? ?????????"
            cell.detailTextLabel?.text = "?????? \(String(format: "%.2fkm",route.distanceInKilometer)) ????????? \(route.paceString)"
        }else {
            let route = routesOthers[indexPath.row]
            cell.textLabel?.text = "\(route.nickname) ?????? ????????? \(route.dateString)"
            cell.detailTextLabel?.text = "?????? \(String(format: "%.2fkm",route.distanceInKilometer)) ????????? \(route.paceString)"
        }
        
        return cell
    }
}

extension Array {
    func uniqueFilter() -> [Log] {
        var result: [Log] = []
        var runnerUids = Set<String>()
        for x in self {
            if let x = x as? Log{
                if !runnerUids.contains(x.runnerUID) {
                    runnerUids.insert(x.runnerUID)
                    result.append(x)
                    print("hello")
                }
            }
        }
        return result
    }
}
