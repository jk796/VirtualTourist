//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Jimin Kim on 3/12/21.
//  Copyright © 2021 Jimin Kim. All rights reserved.
//

import Foundation
import MapKit


class FlickrClient {
    static let apiKey = "57413874747f936b65b23867d2645c29"
    static let secretKey = "4e9106ee2e60ef94"
    
    class func getTotalNumberOfPhotos(coordinate: CLLocationCoordinate2D, completion: @escaping(String?, Error?) -> Void) {
        let latitude = String(coordinate.latitude)
        let longitude = String(coordinate.longitude)
        let task = URLSession.shared.dataTask(with: URL(string: "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(latitude)&lon=\(longitude)&radius=5&per_page=1&format=json&nojsoncallback=1&extras=url_q")!) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(PagedPhotosResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject.photos.total!, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
    
    class func getPhotos(randomPage:String, coordinate: CLLocationCoordinate2D, completion: @escaping(PagedPhotosResponse?, Error?) -> Void) {
        let latitude = String(coordinate.latitude)
        let longitude = String(coordinate.longitude)
        let task = URLSession.shared.dataTask(with: URL(string: "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(latitude)&lon=\(longitude)&radius=5&per_page=9&page=\(randomPage)&format=json&nojsoncallback=1&extras=url_q")!) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(PagedPhotosResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
    
    public class func downloadImage(imageURL: URL, completionHandler: @escaping (Data?, Error?) -> Void ){
                
        let task = URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
            return
            }
            DispatchQueue.main.async {
                completionHandler(data,nil)
            }
        }
        task.resume()
    }
}
