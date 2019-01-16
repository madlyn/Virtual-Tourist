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
    var pin : Pin!
    var page = 1
    var insertedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupContext()
        getImages()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        fetchedResultsController = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setMap()
    }
    
    
    fileprivate func setupContext() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        dataController = delegate.dataController
    }
    
    fileprivate func downloadFromFlickr() {
        let manager = FlickrWebManager()
        manager.displayImageFromFlickrBySearch(lat: pin.lat, long: pin.long, page: page) { (result, error) in
            if let error = error{
                debugPrint(error)
                return
            }
            for pic in result!{
                self.saveImage(url : pic)
            }
            
            if result?.count == 0{
                DispatchQueue.main.async {
                    self.collection.isHidden = true
                }
                
            }
        }
    }
    
    fileprivate func getImages() {
        let fetchRequest : NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "dateAdded", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            if fetchedResultsController.fetchedObjects?.count == 0{
                downloadFromFlickr()
            }
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
    }
    
    fileprivate func saveImage(url : String){
        let pic = Photo(context: self.dataController.viewContext)
        pic.url = url
        pic.pin = self.pin
        pic.dateAdded = Date()
        try? self.dataController.viewContext.save()
    }
    
    fileprivate func downloadImage(picture : Photo , completionHandler: @escaping ( _ data: Data?) -> Void){
        let downloader = ImageDownloader()
        downloader.downloadImage(imagePath: picture.url!) { (data, error) in
            guard error == nil else{
                print(error)
                return
            }
            picture.data = data
            try? self.dataController.viewContext.save()
            
        }
    }
    
    @IBAction func newCollectionTapped(_ sender: Any) {
        for object in fetchedResultsController!.fetchedObjects!{
            dataController.viewContext.delete(object)
        }
        try? dataController.viewContext.save()
        page += 1
        downloadFromFlickr()
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
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let picture = fetchedResultsController.object(at: indexPath)
         let cell = collection.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! ImageCollectionViewCell
        cell.image.image = #imageLiteral(resourceName: "Placeholder")
        if picture.data == nil{
            downloadImage(picture: picture) { (data) in
                cell.image.image = UIImage(data: data!)
            }
        } else{
            cell.image.image = UIImage(data: picture.data!)
        }
       

        return cell;

    }
    
    var selectedIndex : IndexPath!
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = indexPath
        let photo = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photo)
        try! dataController.viewContext.save()
    }
    
}

extension PhotoAlbumViewController:NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //clear arrays
        insertedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            print("insert object")
            insertedIndexPaths.append(newIndexPath!)
            break
        case .update:
            print("update object")
            updatedIndexPaths.append(indexPath!)
            break
        case .delete:
            print("delete object")
            deletedIndexPaths.append(indexPath!)
            break
        default:
            print("DEFAULT - no other action needed")
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collection.performBatchUpdates({() -> Void in
            for indexPath in self.insertedIndexPaths {
                self.collection.insertItems(at: [indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                print("indexPathinfo: \(indexPath)")
                self.collection.reloadItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                print("indexPathinfo: \(indexPath)")
                self.collection.deleteItems(at: [indexPath])
            }
        }, completion: nil)
    }
    
}


