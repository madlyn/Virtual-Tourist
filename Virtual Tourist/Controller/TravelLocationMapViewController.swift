//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Lyn Almasri on 12/16/18.
//  Copyright © 2018 lynmasri. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    var fetchedResultsController : NSFetchedResultsController<Pin>!
    var dataController : DataController!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchResultsController()
        addAnnotations()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        fetchedResultsController = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var delegate = UIApplication.shared.delegate as! AppDelegate
        dataController = delegate.dataController
        deleteButton.isHidden = true
        title = "Virtual Tourist"
        mapView.delegate = self
        if let locationData = UserDefaults.standard.dictionary(forKey: "location"){
            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: locationData["lat"] as! CLLocationDegrees, longitude: locationData["long"] as! CLLocationDegrees), span: MKCoordinateSpan(latitudeDelta: locationData["latDelta"] as! CLLocationDegrees, longitudeDelta: locationData["longDelta"] as! CLLocationDegrees))
            mapView.setRegion(region, animated: true)
        }
        // add gesture recognizer
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(dropPin(_:)))
        longTap.minimumPressDuration = 1.5 // in seconds
        mapView.addGestureRecognizer(longTap)
        
        
    }
    
    fileprivate func setupFetchResultsController() {
        let fetchRequest : NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lat", ascending: true)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch()
        } catch{
            fatalError()
        }
    }
    
    func addAnnotations(){
        if let locations = fetchedResultsController!.fetchedObjects{
            for location in locations{
                let newPin = MKPointAnnotation()
                newPin.coordinate.latitude = location.lat
                newPin.coordinate.longitude = location.long
                mapView.addAnnotation(newPin)
            }
        }
       
    }
    
    @objc func dropPin(_ recognizer: UIGestureRecognizer){
        let touchedAt = recognizer.location(in: self.mapView) // adds the location on the view it was pressed
        let touchedAtCoordinate : CLLocationCoordinate2D = mapView.convert(touchedAt, toCoordinateFrom: self.mapView) // will get coordinates
        
        let newPin = MKPointAnnotation()
        newPin.coordinate = touchedAtCoordinate
        mapView.addAnnotation(newPin)
        let pin = Pin(context: dataController.viewContext)
        pin.lat = touchedAtCoordinate.latitude
        pin.long = touchedAtCoordinate.longitude
        
        try? dataController.viewContext.save()
    }

    @IBAction func editPins(_ sender: Any) {
        toggleEditButton()
    }
    
    func toggleEditButton(){
        if deleteButton.isHidden{
            deleteButton.isHidden = false
            editButton.title = "Done"
        } else{
            deleteButton.isHidden = true
            editButton.title = "Edit"
        }
    }
    
    
   
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        var selectedAnnotation = view.annotation as? MKPointAnnotation
        var selectedPin : Pin!
        try? fetchedResultsController.performFetch()
        for location in fetchedResultsController!.fetchedObjects!{
            if location.lat == selectedAnnotation?.coordinate.latitude && location.long == selectedAnnotation?.coordinate.longitude{
                selectedPin = location
            }
        }
        if deleteButton.isHidden == false{
            dataController.viewContext.delete(selectedPin)
            try? dataController.viewContext.save()
            mapView.removeAnnotation(selectedAnnotation!)
            
        } else{
            let destination = storyboard?.instantiateViewController(withIdentifier: "photoAlbum") as! PhotoAlbumViewController
            destination.pin = selectedPin
            navigationController?.pushViewController(destination, animated: true)
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
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let defaults = UserDefaults.standard
        let locationData = ["lat":mapView.centerCoordinate.latitude
            , "long":mapView.centerCoordinate.longitude
            , "latDelta":mapView.region.span.latitudeDelta
            , "longDelta":mapView.region.span.longitudeDelta]
        defaults.set(locationData, forKey: "location")
    }
    
}
