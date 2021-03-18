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
    
    var coordinate: CLLocationCoordinate2D!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
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
        
        // Configure flowLayout
        let space:CGFloat = 1.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
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
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setUpFetchedResultsController()
        
        if pin!.firstTimeOpen == true {
            downloadPhotos()
            pin?.firstTimeOpen = false
        } else {
            collectionView.delegate = self
            collectionView.dataSource = self
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    fileprivate func deletePhotos() {
        if let photos = self.fetchedResultsController.fetchedObjects {
            for photo in photos {
                self.dataController.viewContext.delete(photo)
                try? self.dataController.viewContext.save()
            }
            downloadPhotos()
        }
    }
    
    fileprivate func downloadPhotos() {
        FlickrClient.getTotalNumberOfPhotos(coordinate: coordinate) { (totalNumber, error) in
            if error != nil {
                self.showFailure(message: error!.localizedDescription)
            } else {
                let totalNumberInt = Int(totalNumber!)
                let randomPageNumber = String(Int.random(in: 0...(totalNumberInt!/9))+1)
                // Load photos of selected location
                FlickrClient.getPhotos(randomPage: randomPageNumber, coordinate: self.coordinate) { (pagedPhotosResponse, error) in
                    if error != nil {
                        self.showFailure(message: error!.localizedDescription)
                        print("\(error?.localizedDescription)")
                    } else {
                        for photoResponse in (pagedPhotosResponse?.photos.photo)! {
                            let photo = Photo(context: self.dataController.viewContext)
//                            let imageURL = URL(string: photoResponse.url_q!)
//                            let imageData = try! Data(contentsOf: imageURL!)
                            photo.creationDate = Date()
                            photo.pin = self.pin
                            photo.imageData = nil
                            photo.imageURL = photoResponse.url_q
                            try? self.dataController.viewContext.save()
                        }
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
        
        if fetchedResultsController.object(at: indexPath).imageData != nil {
            cell.imageView.image = UIImage(data: fetchedResultsController.object(at: indexPath).imageData!)
        } else {
            cell.imageView.image = UIImage(named: "placeholder")
            DispatchQueue.global().async {
                FlickrClient.downloadImage(imageURL: URL(string: self.fetchedResultsController.object(at: indexPath).imageURL!)!) { (data, error) in
                    if error != nil {
                        self.showFailure(message: error!.localizedDescription)
                    } else {
                        cell.imageView.image = UIImage(data: data!)
                        self.fetchedResultsController.object(at: indexPath).imageData = data
                        try? self.dataController.viewContext.save()
                    }
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
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
        deletePhotos()
    }

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
