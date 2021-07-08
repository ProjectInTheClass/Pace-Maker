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
            // 최고 기록
            guard let paceInSeconds = routesBySelf.max(by: { lhs, rhs in
                lhs.pace < rhs.pace
            })?.pace else { return }
            
            bestRecordLabel.text = "km 당 \(paceInSeconds / 60) 분 \(paceInSeconds % 60) 초"
            
            // 최근 기록
            guard let latestRecordPaceInSeconds = routesBySelf.first?.pace else { return }
            latestRecordLabel.text = "km 당 \(latestRecordPaceInSeconds / 60) 분 \(latestRecordPaceInSeconds % 60) 초"
            
        }else {
            bestRecordLabel.text = "- : --"
            latestRecordLabel.text = "- : --"
        }
    }
    
    /// 다음화면으로 넘어가는 경우는, 테이블 뷰 셀을 하나 선택했거나, 가장 위에있는 나의 기록을 눌렀을때로 나뉜다.
    /// RouteDetailViewController 의 log 를 세팅해주면서 넘어간다.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nextViewController = segue.destination as? RouteDetailViewController{
            if let indexPath = tableView.indexPathForSelectedRow {
                // table view cell 터치
                let selectedRoute = indexPath.section == 1 ? routesBySelf[indexPath.row] : routesOthers[indexPath.row]
                nextViewController.log = selectedRoute
            }else {
                // 내 최고기록-최근기록 이랑 경쟁하려는 경우 (table view 와 무관)
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
            return "나의 기록"
        }else {
            return "친구들의 기록"
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
            return "총 \(routesBySelf.count) 번의 달리기"
        }else {
            return "총 \(routesOthers.count) 명의 달리기"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RoutesTableViewCell",for: indexPath)
        
        if indexPath.section == 0 {
            let route = routesBySelf[indexPath.row]
            
            cell.textLabel?.text = "\(route.dateString) 날의 달리기"
            cell.detailTextLabel?.text = "거리 \(String(format: "%.2fkm",route.distanceInKilometer)) 페이스 \(route.paceString)"
        }else {
            let route = routesOthers[indexPath.row]
            cell.textLabel?.text = "\(route.nickname) 님의 달리기 \(route.dateString)"
            cell.detailTextLabel?.text = "거리 \(String(format: "%.2fkm",route.distanceInKilometer)) 페이스 \(route.paceString)"
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
