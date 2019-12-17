//
//  PhotoAlbumViewCell.swift
//  VirtualTourist
//
//  Created by Faisal Babkoor on 12/5/19.
//  Copyright © 2019 Faisal Babkoor. All rights reserved.
//

import UIKit
import CoreData
import Kingfisher

class PhotoAlbumViewCell: UICollectionViewCell {
    @IBOutlet var photoAlbum: UIImageView!
    func configureCell(photo: Photo) {
        let width = (UIScreen.main.bounds.width - 30) / 2
                let height = width * 1.5
        photoAlbum.heightAnchor.constraint(lessThanOrEqualToConstant: height).isActive = true
        photoAlbum.widthAnchor.constraint(lessThanOrEqualToConstant: width).isActive = true

        // Load images from Core Data
        if let image = photo.getImage() {
            print("Load Image from Core Data")
            photoAlbum.image = image
        } else {
            // load data from flickr
            guard let photourl = photo.url else { return }
            guard let url = URL(string: photourl) else { return }
            photoAlbum.kf.indicatorType = .activity
            print("load data from flickr")
            photoAlbum.kf.setImage(with: url, placeholder: #imageLiteral(resourceName: "VirtualTourist_152"), options: [.memoryCacheExpiration(.expired), .diskCacheExpiration(.expired)], progressBlock: nil) { result in
                switch result{
                case .success(let value):
                    photo.image = value.image.jpegData(compressionQuality: 1) as Data?
                    try? DataController.shared.viewContext.save()
                case .failure(let error):
                    print("Job failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
