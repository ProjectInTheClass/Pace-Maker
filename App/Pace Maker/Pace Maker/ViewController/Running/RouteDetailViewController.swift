//
//  RouteDetailViewController.swift
//  Pods
//
//  Created by Kyungho on 2021/05/28.
//

import UIKit
import MapKit
import CoreGPX
import FirebaseStorage
import CoreLocation

var competitorPolyline: MKPolyline? = nil

class RouteDetailViewController: UIViewController {
    
    let MAP_VIEW_SCALE_FACTOR: Double = 2.0
    
    var rootGPX: GPXRoot? = nil
    var log: Log? = nil
    var secondaryLog: Log? = nil
    
    var pace: Int? = nil
    
    @IBOutlet weak var paceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadGPX()
        setMapView()
        updateUI()
        updateLabels()
        // addBottomSheetView()
    }
    
    func updateUI(){
        updateDetailedRouteUI()
    }
    
    func updateLabels(){
        guard let log = log else { return }
        if pace != nil {
            paceLabel.text = "목표 페이스 \(log.pace / 60):\(log.pace % 60)"
        }
    }
    
    func updateDetailedRouteUI(){
        guard let log = log else { return }

        self.title = "\(log.nickname) 님의 달리기"
        paceLabel.text = "페이스: 1 km 당 \(log.paceString)"
        distanceLabel.text = "거리: \(String(format: "%.2f", log.distanceInKilometer)) km"
        let (hour, minute, second): (Int, Int, Int) = log.timeDescription
        if hour != 0 {
            timeLabel.text = "시간: \(hour) 시간 \(minute) 분 \(second) 초"
        }else if minute != 0 {
            timeLabel.text = "시간: \(minute) 분 \(second) 초"
        }else{
            timeLabel.text = "시간: \(second) 초"
        }
        paceLabel.text = "\(log.paceDescription)"
    }
    
    func downloadGPX(){
        guard let selectedRoute = log else { return }
        let fileName = selectedRoute.routeSavedPath
        let filePath = fileName + ".gpx"
        
        storage.reference(forURL: "gs://pace-maker-74452.appspot.com/routes").child(filePath).downloadURL { (url, error) in
            guard let url = url else { return }
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            self.rootGPX = GPXParser(withURL: url)?.parsedData()
            self.createPath()
        }
    }
    
    func createPath() {
        guard let rootGPX = self.rootGPX else { return }
        
        let trackPoints = rootGPX.tracks[0].segments[0].points
        let coords: [CLLocationCoordinate2D] = trackPoints.filter { trackPoint in
            guard let _ = trackPoint.latitude else { return false }
            guard let _ = trackPoint.longitude else { return false }
            return true
        }.map { trackPoint in
            return CLLocationCoordinate2D(latitude: trackPoint.latitude!, longitude: trackPoint.longitude!)
        }
        
        do {
            print("Typed pointers")
            let count = coords.count
            let pointer = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: count)
            pointer.initialize(repeating: coords[0], count: count)
            defer {
                pointer.deinitialize(count: count)
                pointer.deallocate()
            }
            
            for i in 1..<count {
                pointer.advanced(by: i).pointee = coords[i]
            }
            
            let bufferPointer = UnsafeBufferPointer(start: pointer, count: count)
            
            competitorPolyline = MKPolyline(coordinates: pointer, count: count)
            
            guard let competitorPolyline = competitorPolyline else { return }
            
            self.mapView.addOverlay(competitorPolyline, level: .aboveLabels)
            
            var rect = competitorPolyline.boundingMapRect
            
            let adjustedPadding = (MAP_VIEW_SCALE_FACTOR - 1) / 2
            rect.origin = MKMapPoint(x: rect.origin.x - rect.size.width * adjustedPadding, y: rect.origin.y - rect.size.height * adjustedPadding)
            rect.size = MKMapSize(width: rect.size.width * MAP_VIEW_SCALE_FACTOR, height: rect.size.height * MAP_VIEW_SCALE_FACTOR)
            
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }
    
    func createPath(with sourceLocation:CLLocationCoordinate2D,and destinationLocation:CLLocationCoordinate2D){
        
        let sourcePlacemark = MKPlacemark(coordinate: sourceLocation)
        let destinationPlacemakr = MKPlacemark(coordinate: destinationLocation)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemakr)
        
        let sourceAnnotation = MKPointAnnotation()
        sourceAnnotation.title = "start"
        sourceAnnotation.subtitle = "sub title of start"
        if let location = sourcePlacemark.location {
            sourceAnnotation.coordinate = location.coordinate
        }
        
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.title = "destination"
        destinationAnnotation.subtitle = "dest sub title"
        if let location = destinationPlacemakr.location {
            destinationAnnotation.coordinate = location.coordinate
        }
        
        self.mapView.showAnnotations([sourceAnnotation,destinationAnnotation], animated: true)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .walking
        
        let direction = MKDirections(request: directionRequest)
        
        direction.calculate() { (response, error) in
            guard let response = response else {
                if let error  = error {
                    print("Error Found : \(error.localizedDescription)")
                }
                return
            }
            let route = response.routes[0]
            self.mapView.addOverlay(route.polyline, level: .aboveLabels)
            
            let rect = route.polyline.boundingMapRect
            
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }
    
    func addBottomSheetView() {
        // 1- Init bottomSheetVC
        let bottomSheetVC = RunningSettingViewController()
        
        // 2- Add bottomSheetVC as a child view
        self.addChild(bottomSheetVC)
        self.view.addSubview(bottomSheetVC.view)
        bottomSheetVC.didMove(toParent: self)
        
        // 3- Adjust bottomSheet frame and initial position.
        let height = view.frame.height
        let width  = view.frame.width
        bottomSheetVC.view.frame = CGRect(x: 0, y: self.view.frame.maxY, width: width, height: height)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nextVC = segue.destination as? RunningViewController {
            nextVC.goalPace = log?.pace
            nextVC.goalDistance = log?.distanceInKilometer
            nextVC.goalElapsedTime = log?.timeSpentInSeconds
        }
    }
}

extension RouteDetailViewController : MKMapViewDelegate {
    func setMapView() {
        self.mapView.delegate = self
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? MKPolyline {
            let gradientColors = [UIColor.orange, UIColor.blue, UIColor.black, UIColor.red]
            
            /// Initialise a GradientPathRenderer with the colors
            let polylineRenderer = GradientPathRenderer(polyline: overlay, colors: gradientColors)
            
            /// set a linewidth
            polylineRenderer.lineWidth = 7
            return polylineRenderer
        } else {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.lineWidth = 5
            renderer.strokeColor = .systemOrange
            
            return renderer
        }
    }
}
