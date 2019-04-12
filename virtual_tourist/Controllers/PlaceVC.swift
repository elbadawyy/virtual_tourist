//
//  PlaceVC.swift
//  virtual_tourist
//
//  Created by Muhammad El-Badawy on 4/12/19.
//  Copyright © 2019 Muhammad El-Badawy. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit

class PlacesViewController: UIViewController{
    @IBOutlet weak var placeView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    var pin: Pin? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tabController = tabBarController as! TabViewController
        self.pin = tabController.pin
        addPin()
        let predicate = NSPredicate(format: "pin == %@", pin!)
        fetchRequest.predicate = predicate
        
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch()
        }catch{
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    
    func addPin(){
        let annotation = MKPointAnnotation()
        let latitude = CLLocationDegrees((pin?.latitude)!)
        let longitude = CLLocationDegrees((pin?.longitude)!)
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 100_000, longitudinalMeters: 100_000)
        
        mapView.setRegion(region, animated: false)
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
}

extension PlacesViewController: UITableViewDelegate,UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceCell", for: indexPath)
        let item = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = item.title
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch (editingStyle) {
        case .delete:
            let item = fetchedResultsController.object(at: indexPath)
            CoreDataController.shared.viewContext.delete(item)
            try? CoreDataController.shared.saveContext()
        default:
            return
        }
    }
}

extension PlacesViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            placeView.insertRows(at: [newIndexPath!], with: .fade)
            break
        case .delete:
            placeView.deleteRows(at: [indexPath!], with: .fade)
            break
        case .update:
            placeView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            placeView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert: placeView.insertSections(indexSet, with: .fade)
        case .delete: placeView.deleteSections(indexSet, with: .fade)
        case .update: placeView.reloadSections(indexSet, with: .fade)
        case  .move:
            fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        placeView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        placeView.endUpdates()
    }
}
