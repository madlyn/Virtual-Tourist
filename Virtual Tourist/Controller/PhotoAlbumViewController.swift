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
    var pictures = [Data]()
    var pin : Pin!
    var observerToken : Any?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupContext()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        fetchedResultsController = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setMap()
        getImages()
        addNewImageObserver()
        
    }
    
    deinit {
        removeNewImageObserver()
    }
    
    fileprivate func setupContext() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        dataController = delegate.dataController
        backgroundContext = dataController.backgroundContext
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
            self.pictures.append(data!)
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
        return pictures.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collection.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! ImageCollectionViewCell
                cell.image.image = UIImage(data: pictures[indexPath.row])
        return cell;
        
        
    }
    
}

extension PhotoAlbumViewController{
    func addNewImageObserver(){
        removeNewImageObserver()
        observerToken = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: dataController?.viewContext, queue: nil, using: handleNewImageObserver(notification:))
    }
    func removeNewImageObserver(){
        if let token = observerToken{
            NotificationCenter.default.removeObserver(token)
        }
    }
    func handleNewImageObserver(notification : Notification){
        DispatchQueue.main.async {
            self.collection.reloadData()
            print("updating")
        }
    }
    
}


