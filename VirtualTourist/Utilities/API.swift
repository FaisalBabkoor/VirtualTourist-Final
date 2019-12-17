//
//  API.swift
//  VirtualTourist
//
//  Created by Faisal Babkoor on 12/5/19.
//  Copyright © 2019 Faisal Babkoor. All rights reserved.
//

import Foundation

class API {
    static let shared = API()
    private let key = "1dbc0b4d90b3300cd78a2b3b8d301d3d"
    private let secret = "688c4a60317e1ea7"
    private let baseURL = "https://api.flickr.com/services/rest"
    //https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=1dbc0b4d90b3300cd78a2b3b8d301d3d&format=json&nojsoncallback=1&per_page=10&lat=24.786307&lon=46.661142&page=1
    //https://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}.jpg

    func getPhotoURL(id: String, server: String, secret: String, farm: Int) -> String {
        return "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret).jpg"
    }
    
    
    func getImages(lat: Double, lon: Double, page: Int, completionHandler: @escaping ([String]) -> ()){
       let urlString = "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(key)&format=json&nojsoncallback=1&per_page=10&lat=\(lat)&lon=\(lon)&page=\(page)"
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                debugPrint(error!.localizedDescription)
                return
            }
                        guard let data = data else { return }

            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            guard let photos = json!["photos"] as? [String: Any] else { return }
            guard let photo = photos["photo"] as? [[String: Any]] else { return }
            var urls = [String]()
            for urlPhoto in photo{
                let id = urlPhoto["id"] as! String
                let farm = urlPhoto["farm"] as! Int
                let server = urlPhoto["server"] as! String
                let secret = urlPhoto["secret"] as! String
                let url = self.getPhotoURL(id: id, server: server, secret: secret, farm: farm)
                urls.append(url)
            }
            completionHandler(urls)
        }.resume()
    }
}
