//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Faisal Babkoor on 12/5/19.
//  Copyright © 2019 Faisal Babkoor. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import SystemConfiguration

class PhotoAlbumViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var noImageLabel: UILabel!
    @IBOutlet var newCollection: UIButton!
    
    
    let distansInMeters: Double = 10000
    var fetchResult: NSFetchedResultsController<Photo>!
    var pin: Pin!
    var location: CLLocationCoordinate2D?
    var page: Int = 0
    
    var isEmpty: Bool {
        if fetchResult.fetchedObjects?.count ?? 0 == 0 {
            return true
        }else {
            return false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showAlert()
        fetch()
        collectionView.delegate = self
        collectionView.dataSource = self
        mapView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupMap()
        newCollection.isEnabled = isInternetAvailable()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchResult = nil
    }
    
    func fetch() {
        let fetchReques: NSFetchRequest = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        let predicate = NSPredicate(format: "pin == %@", pin)
        
        fetchReques.predicate = predicate
        fetchReques.sortDescriptors = [sortDescriptor]
        fetchResult = NSFetchedResultsController(fetchRequest: fetchReques, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchResult.delegate = self
        do {
            try fetchResult.performFetch()
            if isEmpty {
                //fech new images if there is internet connection
                if isInternetAvailable() {
                    fetchNewImage()
                }
            }
        } catch {
            print("No Data")
        }
    }
    
    @IBAction func newCollectionButtonWasPressed(_ sender: UIButton) {
        if isInternetAvailable() {
            fetchNewImage()
        }
    }
    
    func fetchNewImage() {
        page += 1
        //Load new Images
        loadNewImages()
    }
    
    func loadNewImages() {
        // when I want to download new images I need to delete old Images that saved in Core Data and then download new one
        if !isEmpty {
            let photos = fetchResult.fetchedObjects!
            for photo in photos {
                DataController.shared.viewContext.delete(photo)
            }
            try? DataController.shared.viewContext.save()
        }
        
        API.shared.getImages(lat: location?.latitude ?? 0.0, lon: location?.longitude ?? 0.0, page: page) { (newImagesURL) in
            DispatchQueue.main.async {
                self.noImageLabel.isHidden = newImagesURL.count == 0 ? false : true
                self.newCollection.isEnabled = self.noImageLabel.isHidden ? true : false
            }
            for iamgeurl in newImagesURL {
                let photo = Photo(context: DataController.shared.viewContext)
                photo.url = iamgeurl
                photo.pin = self.pin
            }
            try? DataController.shared.viewContext.save()
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    func setupMap() {
        guard let coordinate = location else { return }
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000000, longitudinalMeters: 1000000)
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = coordinate
        mapView.setRegion(region, animated: true)
        mapView.addAnnotation(pointAnnotation)
    }
}


extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchResult.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.CellsIdentifier.photoCell, for: indexPath) as? PhotoAlbumViewCell else { return UICollectionViewCell() }
        let photo = fetchResult.object(at: indexPath)
        cell.configureCell(photo: photo)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photo = fetchResult.object(at: indexPath)
        DataController.shared.viewContext.delete(photo)
        try? DataController.shared.viewContext.save()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
         let width = (UIScreen.main.bounds.width - 30) / 2
         let height = width * 1.5
         return CGSize(width: width, height: height)
     }
    
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPinAnnotationView else { return nil }
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: Identifiers.PinIdentifier.pinID) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Identifiers.PinIdentifier.pinID)
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert, .delete:
            collectionView.reloadData()
        default:
            return
        }
    }
}

// Check newtwork connection
extension PhotoAlbumViewController {
    func isInternetAvailable() -> Bool {
           var zeroAddress = sockaddr_in()
           zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
           zeroAddress.sin_family = sa_family_t(AF_INET)

           let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
               $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                   SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
               }
           }

           var flags = SCNetworkReachabilityFlags()
           if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
               return false
           }
           let isReachable = flags.contains(.reachable)
           let needsConnection = flags.contains(.connectionRequired)
           return (isReachable && !needsConnection)
       }

       func showAlert() {
        if !isInternetAvailable() {
        ShowAlert.showAlert(title: "Warning", message: "Please check your internet connection.", vc: self)
            }
       }
}
