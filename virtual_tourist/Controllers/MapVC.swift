//
//  MapVC.swift
//  virtual_tourist
//
//  Created by Muhammad El-Badawy on 4/12/19.
//  Copyright © 2019 Muhammad El-Badawy. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var editToolBar: UIButton!
    var pin: Pin? = nil
    let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
    var editable = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        editToolBar.isHidden = true
        loadPins()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PlaceSegue" {
            let controller = segue.destination as! TabViewController
            controller.pin = self.pin
        }
    }
    
    @IBAction func longPressedGesture(_ sender: AnyObject) {
        if sender.state == .began {
            addingPin(sender: sender)
        } else if sender.state == .ended {
            Client.sharedInstance.getPhotos(pin!)
            CoreDataController.shared.saveContext()
        }
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        if editable{
            editButton.title = "Done"
            editToolBar.isHidden = false
            editable = false
        }else{
            editButton.title = "Edit"
            editToolBar.isHidden = true
            editable = true
        }
    }
    
    func addingPin(sender: AnyObject){
        let location = sender.location(in: mapView)
        let locCoord = mapView.convert(location, toCoordinateFrom: mapView)
        var pinAnnotation = MKPointAnnotation()
        pinAnnotation.coordinate = locCoord
        
        let pin: Pin = Pin(context: CoreDataController.shared.viewContext)
        pin.latitude = pinAnnotation.coordinate.latitude
        pin.longitude = pinAnnotation.coordinate.longitude
        self.pin = pin as! Pin
        self.mapView.addAnnotation(pinAnnotation)
    }
}

extension MapViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        let latitude = (view.annotation?.coordinate.latitude)!
        let longitude = (view.annotation?.coordinate.longitude)!
        let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", "\(latitude)", "\(longitude)")
        fetchRequest.predicate = predicate
        
        if editable{
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
            fetchRequest.predicate = predicate
            guard let pin = (try? CoreDataController.shared.viewContext.fetch(fetchRequest))!.first else {
                return
            }
            self.pin = pin as! Pin
            performSegue(withIdentifier: "PlaceSegue", sender: self)
        }else{
            if let result = try? CoreDataController.shared.viewContext.fetch(fetchRequest){
                for res in result{
                    CoreDataController.shared.viewContext.delete(res)
                    try? CoreDataController.shared.saveContext()
                }
                self.mapView.removeAnnotation(view.annotation!)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            let app = UIApplication.shared
            if let toOpen = view.annotation?.subtitle! {
                app.openURL(URL(string: toOpen)!)
            }
        }
    }
    
    func loadPins(){
        var annotations = [MKPointAnnotation]()
        
        do{
            if let result = try? CoreDataController.shared.viewContext.fetch(fetchRequest){
                for pin in result {
                    let lat = CLLocationDegrees(pin.latitude as! Double)
                    let long = CLLocationDegrees(pin.longitude as! Double)
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = coordinate
                    annotations.append(annotation)
                }
                self.mapView.addAnnotations(annotations)
            }
        }catch{
            print("Error in adding pins")
        }
    }
}

