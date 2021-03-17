//
//  MapViewViewController.swift
//  VirtualTourist
//
//  Created by Jimin Kim on 3/13/21.
//  Copyright © 2021 Jimin Kim. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var pin: Pin?
    var pins: [Pin] = []
    let regionSpanKey = "regionSpanKey"
    var coordinate: CLLocationCoordinate2D?
    
    var dataController: DataController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        mapView.delegate = self
        
        // Add long press recognizer
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress(sender:)))
        mapView.addGestureRecognizer(longPressRecognizer)
        
        // Load mapView with last location and zoom
        if let regionSpan = UserDefaults.standard.dictionary(forKey: regionSpanKey) {
            let location = regionSpan as! [String: CLLocationDegrees]
            let center = CLLocationCoordinate2D(latitude: location["latitude"]!, longitude: location["longitude"]!)
            let span = MKCoordinateSpan(latitudeDelta: location["latitudeDelta"]!, longitudeDelta: location["longitudeDelta"]!)
            mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
        }
        
        // Load saved pins from persistent store
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            pins = result
        }
        for pin in pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate.latitude = pin.latitude
            annotation.coordinate.longitude = pin.longitude
            self.mapView.addAnnotation(annotation)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        

    }
    

    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            //pinView!.canShowCallout = true
            pinView!.pinColor = .red
            //pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        coordinate = view.annotation?.coordinate
        let annotationPin = view.annotation
        for pin in pins {
            if pin.latitude == annotationPin!.coordinate.latitude && pin.longitude == annotationPin!.coordinate.longitude {
                self.pin = pin
            }
        }
        
        mapView.deselectAnnotation(annotationPin, animated: true)
        performSegue(withIdentifier: "ShowPhotoAlbum", sender: self)
    }
    
    @objc func longPress(sender: UILongPressGestureRecognizer) {
        if sender.state != .began {
            return
        }
        let touchPoint = sender.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        pin.firstTimeOpen = true
        try? dataController.viewContext.save()
        pins.append(pin)
        self.mapView.addAnnotation(annotation)
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        self.saveRegionSpan()
    }
    
    func saveRegionSpan() {
        let regionSpan = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        UserDefaults.standard.set(regionSpan, forKey: regionSpanKey)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPhotoAlbum" {
            let vc = segue.destination as! PhotoAlbumViewController
            vc.pin = pin
            vc.coordinate = coordinate
            vc.dataController = dataController
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
