//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Lyn Almasri on 12/16/18.
//  Copyright © 2018 lynmasri. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collection: UICollectionView!
    
    var dataController: DataController!
    var fetchedResultsController : NSFetchedResultsController<Photo>!
    var backgroundContext : NSManagedObjectContext!
    
    var pin : Pin!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchResultsController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        fetchedResultsController = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setMap()
        getImages()
        
    }
    
    fileprivate func setupFetchResultsController() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        dataController = delegate.dataController
        backgroundContext = dataController.backgroundContext
        let fetchRequest : NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "data", ascending: false)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.backgroundContext, sectionNameKeyPath: nil, cacheName: nil)
        //        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch()
        } catch{
            fatalError()
        }
    }
    
    fileprivate func getImages() {
        let manager = FlickrWebManager()
        manager.displayImageFromFlickrBySearch(lat: pin.lat, long: pin.long) { (result, error) in
            if let error = error{
                print(error)
                return
            }
            for pic in result!{
                self.downloadImage(url: pic)
            }
        }
    }
    
    fileprivate func downloadImage(url : String){
        var downloader = ImageDownloader()
        downloader.downloadImage(url: url) { (data, error) in
            guard error == nil else{
                print(error)
                return
            }
            print("HEllo")
            let pic = Photo(context: self.dataController.backgroundContext)
            pic.data = data
            try? self.backgroundContext.save()
            
            
            
        }
    }
    
    // MARK: - Map Functions
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    fileprivate func setMap() {
        var span = MKCoordinateSpan()
        span.latitudeDelta = 0.01;
        span.longitudeDelta = 0.01;
        var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: pin.lat, longitude: pin.long), span: span)
        mapView.setRegion(region, animated: true)
        mapView.isUserInteractionEnabled = false
        mapView.isZoomEnabled = false
        mapView.isPitchEnabled = false
        let newPin = MKPointAnnotation()
        newPin.coordinate.latitude = pin.lat
        newPin.coordinate.longitude = pin.long
        mapView.addAnnotation(newPin)
    }
    
    // MARK: Collection View
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let photo = fetchedResultsController.object(at: indexPath)
        let cell = collection.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! ImageCollectionViewCell
        //        cell.image.image = UIImage(data: photo.data!)
        return cell;
        
        
    }
    
}

extension PhotoAlbumViewController : NSFetchedResultsControllerDelegate{
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("HEelo1")
        
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //        tableView.endUpdates()
    }
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            print("Hello")
        //            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete: break
        //            tableView.deleteRows(at: [indexPath!], with: .fade)
        default:
            break
        }
    }
}
