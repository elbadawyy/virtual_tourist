//
//  Client.swift
//  virtual_tourist
//
//  Created by Muhammad El-Badawy on 1/12/19.
//  Copyright © 2019 Muhammad El-Badawy. All rights reserved.
//

import Foundation

class Client{
    static let sharedInstance = Client()
    var session = URLSession.shared
    
    func getPhotos(_ pin: Pin){
        var methodParameters = [
            Constants.FlickrParameterkeys.APIKey : Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterkeys.Extras : Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterkeys.Format : Constants.FlickrParameterValues.Format,
            Constants.FlickrParameterkeys.Method : Constants.FlickrParameterValues.Method,
            Constants.FlickrParameterkeys.NoJSONCallBack : Constants.FlickrParameterValues.NoJSONCallBack,
            Constants.FlickrParameterkeys.SafeSearch : Constants.FlickrParameterValues.SafeSearch,
            Constants.FlickrParameterkeys.latitude : "\(pin.latitude)",
            Constants.FlickrParameterkeys.longitude : "\(pin.longitude)",
            Constants.FlickrParameterkeys.BBox : bbox(longitude: pin.longitude, latitude: pin.latitude)
            ] as [String:AnyObject]
        
        let request = URLRequest(url: getURL(parameteres: methodParameters))
        
        let task = session.dataTask(with: request){ (data, response, error) in
            guard (error == nil) else {
                print("There was an error with your request: \(error!)")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("Your request returned a status code other than 2xx!")
                return
            }
            
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            guard let photos = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else{
                print("Cannot find key '\(Constants.FlickrResponseKeys.Photos)'")
                return
            }
            
            guard let photo = photos[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else{
                print("Cannot find key '\(Constants.FlickrResponseKeys.Photo)'")
                return
            }
            
            for photoInfo in photo{
                guard let image = photoInfo[Constants.FlickrResponseKeys.MediumURL] as? String else{
                    print("Cannot find key '\(Constants.FlickrResponseKeys.MediumURL)'")
                    return
                }
                
                guard let title = photoInfo[Constants.FlickrResponseKeys.Title] as? String else{
                    print("there is no title for this image")
                    return
                }
                var place = Photo(context: CoreDataController.shared.viewContext)
                place.imageData = image
                place.title = title
                place.pin = pin
                pin.photos?.adding(place)
            }
            CoreDataController.shared.saveContext()
        }
        task.resume()
    }
    
    func bbox(longitude: Double, latitude: Double) -> String{
        if longitude != nil && latitude != nil{
            let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
            let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
            let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
            let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        }
        else{
            return "0,0,0,0"
        }
    }
    
    func getURL(parameteres parameters: [String:AnyObject]) -> URL{
        var components = URLComponents()
        
        components.host = Constants.Flickr.APIHost
        components.scheme = Constants.Flickr.APIScheme
        components.path = Constants.Flickr.APIPath
        
        components.queryItems =  [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}
