//
//  AlbumVC.swift
//  virtual_tourist
//
//  Created by Muhammad El-Badawy on 4/12/19.
//  Copyright © 2019 Muhammad El-Badawy. All rights reserved.
//

import Foundation
import CoreData
import MapKit
import UIKit

class AlbumViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate{
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollection: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var blockOperation = BlockOperation()
    var pin: Pin? = nil
    var photos: [Photo?] = [Photo?]()
    var selectedPhotos = [NSIndexPath]()
    let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
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

extension AlbumViewController: UICollectionViewDataSource{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! AlbumViewCell
        let item = fetchedResultsController.object(at: indexPath)
        if item.imageData != nil{
            let imageURL = URL(string: item.imageData!)!
            cell.activityIndicator.startAnimating()
            
            let task = URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
                if error == nil {
                    let downloadedImage = UIImage(data: data!)
                    DispatchQueue.main.async{
                        cell.activityIndicator.stopAnimating()
                        cell.activityIndicator.isHidden = true
                        cell.imageCell.image = downloadedImage
                    }
                } else {
                    print(error!)
                }
            }
            task.resume()
        }
        return cell
    }
}

extension AlbumViewController: UICollectionViewDelegate{
    @IBAction func deleteCollection(_ sender: UIButton){
        for item in selectedPhotos{
            let photo = fetchedResultsController.object(at: item as IndexPath)
            CoreDataController.shared.viewContext.delete(photo)
        }
        try? CoreDataController.shared.saveContext()
        selectedPhotos = []
        newCollection.setTitle("New Collection", for: .normal)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! AlbumViewCell
        let index = selectedPhotos.index(of: indexPath as NSIndexPath)
        
        if let index = index {
            selectedPhotos.remove(at: index)
            cell.imageCell.alpha = 1.0
        } else {
            selectedPhotos.append(indexPath as NSIndexPath)
            cell.imageCell.alpha = 0.25
        }
        
        if selectedPhotos.count > 0 {
            newCollection.setTitle("Delete", for: .normal)
            
        } else {
            newCollection.setTitle("New Collection", for: .normal)
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperation = BlockOperation()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let sectionIndexSet = IndexSet(integer: sectionIndex)
        
        switch type {
        case .insert:
            blockOperation.addExecutionBlock {
                self.collectionView?.insertSections(sectionIndexSet)
            }
        case .delete:
            blockOperation.addExecutionBlock {
                self.collectionView?.deleteSections(sectionIndexSet)
            }
        case .update:
            blockOperation.addExecutionBlock {
                self.collectionView?.reloadSections(sectionIndexSet)
            }
        case .move:
            assertionFailure()
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { break }
            
            blockOperation.addExecutionBlock {
                self.collectionView?.insertItems(at: [newIndexPath])
            }
        case .delete:
            guard let indexPath = indexPath else { break }
            
            blockOperation.addExecutionBlock {
                self.collectionView?.deleteItems(at: [indexPath])
            }
        case .update:
            guard let indexPath = indexPath else { break }
            
            blockOperation.addExecutionBlock {
                self.collectionView?.reloadItems(at: [indexPath])
            }
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
            
            blockOperation.addExecutionBlock {
                self.collectionView?.moveItem(at: indexPath, to: newIndexPath)
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView?.performBatchUpdates({
            self.blockOperation.start()
        }, completion: nil)
    }
}
