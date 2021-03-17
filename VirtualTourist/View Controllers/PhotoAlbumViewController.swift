//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Jimin Kim on 3/13/21.
//  Copyright © 2021 Jimin Kim. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    var dataController: DataController!
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    var pin: Pin?
    
    //var photos = [Photo]()
    
    var coordinate: CLLocationCoordinate2D!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var newCollectionButton: UIButton!
    
    fileprivate func setUpFetchedResultsController() {
        // Instantiate fetchedResultsController
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin!)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = false
        // Do any additional setup after loading the view.
        mapView.delegate = self
        
        // mapView's initial center and span based on what the user clicked in MapViewViewController
        let center = coordinate!
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
        
        // Add pin to mapView
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        self.mapView.addAnnotation(annotation)
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setUpFetchedResultsController()
        
        if pin!.firstTimeOpen == true {
            pin!.firstTimeOpen = false
            downloadPhotos()
        } else {
            collectionView.delegate = self
            collectionView.dataSource = self
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    fileprivate func downloadPhotos() {
        FlickrClient.getTotalNumberOfPhotos(coordinate: coordinate) { (totalNumber, error) in
            if error != nil {
                self.showFailure(message: error!.localizedDescription)
            } else {
                let totalNumberInt = Int(totalNumber!)
                let randomPageNumber = String(Int.random(in: 1...(totalNumberInt!/15)))
                // Load photos of selected location
                FlickrClient.getPhotos(randomPage: randomPageNumber, coordinate: self.coordinate) { (pagedPhotosResponse, error) in
                    if error != nil {
                        self.showFailure(message: error!.localizedDescription)
                        print("\(error?.localizedDescription)")
                    } else {
                        if let photos = self.fetchedResultsController.fetchedObjects {
                            for photo in photos {
                                self.dataController.viewContext.delete(photo)
                                try? self.dataController.viewContext.save()
                            }
                        }
                        for photoResponse in (pagedPhotosResponse?.photos.photo)! {
                            let photo = Photo(context: self.dataController.viewContext)
                            let imageURL = URL(string: photoResponse.url_q!)
                            let imageData = try! Data(contentsOf: imageURL!)
                            photo.imageData = imageData
                            photo.creationDate = Date()
                            photo.pin = self.pin
                            try? self.dataController.viewContext.save()
                        }
                        self.collectionView.reloadData()
                       // self.collectionView.numberOfItems(inSection: 0)
                    }
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
        
        cell.imageView.image = UIImage(data: fetchedResultsController.object(at: indexPath).imageData!)
        
        return cell
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
    
    func showFailure(message: String) {
        let alertVC = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true)
    }
    
    @IBAction func newCollectionButtonTapped(_ sender: Any) {
        downloadPhotos()
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


extension PhotoAlbumViewController {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            collectionView.insertItems(at: [newIndexPath!])
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
        default:
            break
        }
    }
}