//
//  Photo+Extensions.swift
//  VirtualTourist
//
//  Created by Faisal Babkoor on 12/5/19.
//  Copyright © 2019 Faisal Babkoor. All rights reserved.
//
import UIKit
import CoreData
extension Photo {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
    func getImage() -> UIImage? {
        if image != nil {
           return UIImage(data: image! as Data)
        } else {
            return nil
        }
    }
}
