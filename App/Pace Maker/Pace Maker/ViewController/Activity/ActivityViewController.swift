//
//  ActivityViewController.swift
//  Pace Maker
//
//  Created by Kyungho on 2021/05/20.
//

import UIKit
import HealthKit
import Charts
import Firebase

class ActivityViewController: UIViewController {

    @IBOutlet weak var deviceNotAvailableLabel: UILabel!
    @IBOutlet weak var syncBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var measureMessagePrefix: UILabel!
    @IBOutlet weak var measuredPeriod: UILabel!
    @IBOutlet weak var summary: UILabel!
    @IBOutlet weak var measureUnit: UILabel!
    
    @IBOutlet weak var barChartView: BarChartView!
    @IBOutlet weak var lineChartView: LineChartView!
    
    @IBOutlet weak var tableView: UITableView!
        
    // Data
    var logs: [Log] = []
    var heartRateData: [(date: Date, value: Double)] = []
    var activeEnergyBurnedData: [(date: Date, value: Double)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setChartView()
        loadDatabase()
        updateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadLogs()
    }
    
    func loadDatabase() {
        loadHealthKitData()
        loadWatchKitData()
    }
    
    func updateUI() {
        updateChart()
        updateTable()
    }
    
    func updateTable(){
        self.tableView.reloadData()
    }
    
    func sortLogs(){
        logs.sort { small, large in
            // print("small \(small.dateString) large\(large.dateString)")
            return small.dateString > large.dateString
        }
    }
    
    @IBAction func changedSegmentControlValue(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        currentMetric = CurrentMetric.allValues[selectedIndex]
        updateUI()
    }
}

// CHART
extension ActivityViewController {
    
    func loadLogs(){
        guard let user = user else { return }
        
        let logReference = realtimeReference.reference(withPath: "log")
        logReference.queryOrdered(byChild: "runner")
            .queryEqual(toValue: user.UID)
            .observeSingleEvent(of: .value) { snapshot in
                print("snapshot.childrenCount", snapshot.childrenCount)
                let snapshot = snapshot.value as? [String : AnyObject] ?? [:]
                self.logs.removeAll()
                // snapshot is an Array of Dictionary
                for logDictonary in snapshot {
                    let singleLog = logDictonary.value
                    let date: String = singleLog["date"] as! String
                    let distance: Double = singleLog["distance"] as! Double
                    let route: String = singleLog["route"] as! String
                    let time: Double = singleLog["time"] as! Double
                    let nickname: String = singleLog["nick"] as! String
                    
                    let runnerId: String = singleLog["runner"] as! String
                    
                    self.logs.append(Log(dateString: date, distanceInKilometer: distance, routeSavedPath: route, runnerUID: runnerId, nickname: nickname, timeSpentInSeconds: time))
                }
                self.logs.sort(){ $0.dateString > $1.dateString }
                self.updateUI()
            }
    }
    
    /// initial setting for chart view
    func setChartView() {
        setBarChartView()
        setLineChartView()
    }
    
    func setBarChartView() {
        barChartView.dragXEnabled = true
        barChartView.dragYEnabled = false
        barChartView.isHidden = true
        barChartView.noDataTextColor = .lightGray
        barChartView.rightAxis.enabled = false
        barChartView.leftAxis.enabled = true
        barChartView.leftAxis.axisMinimum = 0
        barChartView.maxVisibleCount = 10
    }
    
    func setLineChartView() {
        lineChartView.dragXEnabled = true
        lineChartView.dragYEnabled = false
        lineChartView.isHidden = true
        lineChartView.noDataTextColor = .lightGray
        lineChartView.rightAxis.enabled = false
        lineChartView.leftAxis.enabled = true
        lineChartView.leftAxis.axisMinimum = 0
        lineChartView.maxVisibleCount = 10
        lineChartView.moveViewToX(lineChartView.chartXMax)
    } 
    
    func updateBarChartData(with dataEntries:[(String,Double)]){
        if dataEntries.count == 0 { return }
        
        var barChartDataEntries: [BarChartDataEntry] = []
        for i in 0..<dataEntries.count {
            let dataEntry = BarChartDataEntry(x: Double(i), y: dataEntries[i].1)
            barChartDataEntries.append(dataEntry)
        }
        
        let barChartDataSet = BarChartDataSet(entries: barChartDataEntries, label: currentMetric.label)
        barChartDataSet.drawValuesEnabled = true
        let barChartData = BarChartData(dataSet: barChartDataSet)
        barChartView.data = barChartData
    }
    
    func updateLineChartData(with dataEntries:[(String,Double)]){
        if dataEntries.count == 0 { return }

        var lineChartDataEntries: [ChartDataEntry] = []
        for i in 0..<dataEntries.count {
            let dataEntry = ChartDataEntry(x: Double(i), y: dataEntries[i].1)
            lineChartDataEntries.append(dataEntry)
        }
        
        let lineChartDataSet = LineChartDataSet(entries: lineChartDataEntries, label: currentMetric.label)
        lineChartDataSet.drawValuesEnabled = true

        lineChartDataSet.circleRadius = 0
        let lineChartData = LineChartData(dataSet: lineChartDataSet)

        // additional
        let gradientColors = [UIColor.cyan.cgColor, UIColor.clear.cgColor] as CFArray // Colors of the gradient
        let colorLocations:[CGFloat] = [1.0, 0.0] // Positioning of the gradient
        let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations) // Gradient Object
        lineChartDataSet.fill = Fill.fillWithLinearGradient(gradient!, angle: 90.0) // Set the Gradient
        lineChartDataSet.drawFilledEnabled = true // Draw the Gradient
        
        lineChartDataSet.circleRadius = 1
        lineChartDataSet.mode = .cubicBezier
        
        lineChartView.data = lineChartData
    }
    
    func updateChartUI(with dataEntries:[(String,Double)]){
        if dataEntries.count == 0 { return }
        
        let valueSum: Double = dataEntries.reduce(0) { $0 + $1.1 }
        let averageValue = valueSum / Double(dataEntries.count)
        let dates: [Date] = dataEntries.map {
            return dateFormatter.date(from: $0.0)!
        }
        
        // Chart Description Labels
        measureUnit.text = currentMetric.unit
        let distantDateString = dateFormatter.string(from: dates.min()!)
        let recentDateString = dateFormatter.string(from: dates.max()!)
        measuredPeriod.text = (distantDateString == recentDateString) ? distantDateString : "\(distantDateString) ~ \(recentDateString)"
        
        if currentMetric == .pace {
            // 최고기록을 뽑아낸다
            let bestRecord: Double = dataEntries.reduce(Double.greatestFiniteMagnitude) {
                ($0 > $1.1) ? $0 : $1.1
            }
            let pacesInSeconds = Int(bestRecord)
            summary.text = String(format: currentMetric.summaryFormat, pacesInSeconds/60, pacesInSeconds%60)
        }else {
            summary.text = String(format: currentMetric.summaryFormat, currentMetric == .distance ? valueSum : averageValue)
        }
        
        // Charts
        // Switch Current ChartView
        var _chartView: BarLineChartViewBase? = nil
        switch currentMetric {
            case .pace, .distance:
                lineChartView.isHidden = true
                barChartView.isHidden = false
                _chartView = barChartView as BarLineChartViewBase
            case .heartRate, .activeEnergyBurned:
                barChartView.isHidden = true
                lineChartView.isHidden = false
                _chartView = lineChartView as BarLineChartViewBase
        }
        
        guard let chartView = _chartView else { return }
        
        // limit lines
        let averageLine = ChartLimitLine(limit: averageValue, label: currentMetric.limitLineLabel)
        averageLine.lineWidth = 2
        averageLine.label = "\(currentMetric.limitLineLabel)"
        
        chartView.leftAxis.removeAllLimitLines()
        chartView.leftAxis.addLimitLine(averageLine)
        chartView.data?.dataSets.first?.setColor(currentMetric.colorSet)
        chartView.xAxis.labelPosition = .bottom // X축 레이블 위치 조정
        chartView.xAxis.axisMinimum = 0
//        chartView.xAxis.setLabelCount(5, force: true)
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: dataEntries.map({$0.0})) // X축 레이블 포맷 지정
        chartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.8)
        
    }
    
    func updateChart(){
        
        var chartEntries: [(String,Double)] = []
        clearChartLabels()
        lineChartView.clear()
        barChartView.clear()
        switch currentMetric {
            case .distance:
                for log in logs{
                    chartEntries.append((log.dateString,log.distanceInKilometer))
                }
                updateBarChartData(with: chartEntries)
            case .pace:
                for log in logs{
                    chartEntries.append((log.dateString, Double(log.pace)))
                }
                updateBarChartData(with: chartEntries)
            case .heartRate:
                for heartRate in heartRateData {
                    chartEntries.append((dateFormatter.string(from: heartRate.date), heartRate.value))
                }
                updateLineChartData(with: chartEntries)
            case .activeEnergyBurned:
                for activeEneryBurned in activeEnergyBurnedData {
                    chartEntries.append((dateFormatter.string(from: activeEneryBurned.date), activeEneryBurned.value))
                }
                updateLineChartData(with: chartEntries)
        }
        updateChartUI(with: chartEntries)
        
        // 그외 추가로 더 해줘야하는 것들
        measureMessagePrefix.text = currentMetric.prefix
        measureUnit.text = currentMetric.unit
    }
    
    func clearChartLabels(){
        summary.text = "0"
        measuredPeriod.text = "Today"
    }
}

struct HKData{
    let loggedDate: Date
    let value: Double
}

// HEALTH KIT
extension ActivityViewController {
    
    func loadHealthKitData(){
        authorizeHealtKitData()
        requestHealthKitData()
    }
    
    func requestHealthKitData(){
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit Data not available")
            return
        }
        
        requestActiveEnergyBurnedData()
        requestHeartRateData()
    }
    
    func requestHeartRateData(){
        guard let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        getSamples(for: heartRate) { (samples: [HKSample]?, error : Error?) in
            if let _ = error { return }
            guard let samples = samples else { return }
            print("loaded \(samples.count) heartRate data")
            
            // remove unnecessory sample data. only extract date / heartrate value
            let samplesByDate = samples.map { sample -> HKData in
                guard let quantitySample: HKQuantitySample = sample as? HKQuantitySample else { return HKData(loggedDate: Date(), value: 0) }
                return HKData(loggedDate: quantitySample.startDate, value: quantitySample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
            }
            
            // group bpm value by date
            let calendar = Calendar.current
            let samplesGrouped = Dictionary(grouping: samplesByDate, by: {
                [calendar.component(.year, from: $0.loggedDate),
                 calendar.component(.month, from: $0.loggedDate),
                 calendar.component(.day, from: $0.loggedDate)]
            })
            print("samplesGrouped.count",samplesGrouped.count)
            
            // set datasource
            self.heartRateData = []
            for sampleOneDay in samplesGrouped {
                let date: Date = dateFormatter.date(from: "\(sampleOneDay.key[0])-\(sampleOneDay.key[1])-\(sampleOneDay.key[2])")!
                let heartRate: Double = sampleOneDay.value.reduce(0.0){$0 + $1.value} / Double(sampleOneDay.value.count)
                // print(date, heartRate)
                self.heartRateData.append((date, heartRate))
            }
            self.heartRateData.sort { $0.date > $1.date }
        }
    }
    
    func requestActiveEnergyBurnedData(){
        guard let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        getSamples(for: activeEnergy) { (samples: [HKSample]?, error : Error?) in
            if let _ = error { return }
            guard let samples = samples else { return }
            print("loaded \(samples.count) active enery burned data")
            
            // remove unnecessory sample data. only extract date / kilocalories value
            let samplesByDate = samples.map { sample -> HKData in
                guard let quantitySample: HKQuantitySample = sample as? HKQuantitySample else { return HKData(loggedDate: Date(), value: 0) }
                return HKData(loggedDate: quantitySample.startDate, value: Double.rounded(quantitySample.quantity.doubleValue(for: HKUnit.kilocalorie()))())
            }
            
            // group kilocalories value by date
            let calendar = Calendar.current
            let samplesGrouped = Dictionary(grouping: samplesByDate, by: {
                                    [calendar.component(.year, from: $0.loggedDate),
                                     calendar.component(.month, from: $0.loggedDate),
                                     calendar.component(.day, from: $0.loggedDate)]
            })
            print("samplesGrouped.count",samplesGrouped.count)
            
            // set datasource
            self.activeEnergyBurnedData = []
            for sampleOneDay in samplesGrouped {
                let date:Date = dateFormatter.date(from: "\(sampleOneDay.key[0])-\(sampleOneDay.key[1])-\(sampleOneDay.key[2])")!
                let kiloCalories = sampleOneDay.value.reduce(0.0){$0 + $1.value}
                self.activeEnergyBurnedData.append((date, kiloCalories))
            }
            self.activeEnergyBurnedData.sort { $0.date > $1.date }
        }
    }
    
    func getSamples(for sampleType: HKSampleType, completion: @escaping ([HKSample]?, Error?) -> Swift.Void) {
        // 1. Use HKQuery to load the most recent samples.
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            
            // 2. Always dispatch to the main thread when complete.
            DispatchQueue.main.async {
                guard let samples = samples else {
                    completion(nil, error)
                    return
                }
                completion(samples, nil)
            }
        }
        HKHealthStore().execute(sampleQuery)
    }
    
    func authorizeHealtKitData() {
        
        let healthStore = HKHealthStore()

        if HKHealthStore.isHealthDataAvailable() {
            
            let readTypes = Set([HKObjectType.workoutType(),
                                 HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                                 HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                                 HKObjectType.quantityType(forIdentifier: .heartRate)!,
                                 HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
                                 HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage)!
            ])

            let writeTypes = Set([HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!])
            
            healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { (success, error) in
                if !success {
                    // Handle the error here.
                }
            }
        }else {
            // iOS 8 이상에서만 건강 앱과 관련된 작동이 가능하다
            for s in view.subviews {
                s.isHidden = true
            }
            deviceNotAvailableLabel.isHidden = false
        }
    }
}

// WATCH KIT
extension ActivityViewController {
    func loadWatchKitData(){
        
    }
}

// TABLE VIEW
extension ActivityViewController :UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch currentMetric {
            case .distance:
                return logs.count
            case .pace:
                return logs.count
            case .heartRate:
                return heartRateData.count
            case .activeEnergyBurned:
                return activeEnergyBurnedData.count
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch currentMetric {
            case .distance:
                let cell = tableView.dequeueReusableCell(withIdentifier: "distance", for: indexPath)
                let log = logs[indexPath.row]
                cell.textLabel?.text = String(format: "%.2f", log.distanceInKilometer)
                cell.detailTextLabel?.text = log.dateString
                return cell
            case .pace:
                let cell = tableView.dequeueReusableCell(withIdentifier: "pace", for: indexPath)
                let log = logs[indexPath.row]
                cell.textLabel?.text = log.paceString
                cell.detailTextLabel?.text = log.dateString
                return cell
            case .heartRate:
                let cell = tableView.dequeueReusableCell(withIdentifier: "heartRate", for: indexPath)
                let data = heartRateData[indexPath.row]
                cell.textLabel?.text = String.init(format: "%.2f", data.value)
                let daysCount = self.days(from: data.date)
                cell.detailTextLabel?.text = "\(daysCount)일 전"
                return cell
            case .activeEnergyBurned:
                let cell = tableView.dequeueReusableCell(withIdentifier: "activeEnergyBurned", for: indexPath)
                let data = activeEnergyBurnedData[indexPath.row]
                cell.textLabel?.text = "\(Int(data.value))"
                let daysCount = self.days(from: data.date)
                cell.detailTextLabel?.text = "\(daysCount)일 전"
                return cell
        }
    }
    func days(from date:Date) -> Int{
        return Calendar.current.dateComponents([.day], from:date, to: Date()).day! + 1
    }
}
