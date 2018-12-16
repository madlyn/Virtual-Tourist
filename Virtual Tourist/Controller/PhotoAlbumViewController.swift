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

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collection: UICollectionView!
    
    var pin : Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
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
        let manager = FlickrWebManager()
        manager.displayImageFromFlickrBySearch(lat: pin.lat, long: pin.long) { (result, error) in
            if let error = error{
                print(error)
            }
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

}
