//
//  Constants.swift
//  virtual_tourist
//
//  Created by Muhammad El-Badawy on 1/12/19.
//  Copyright © 2019 Muhammad El-Badawy. All rights reserved.
//

import Foundation

struct Constants{
    
    struct Flickr{
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest"
        
        static let SearchBBoxHalfWidth = 1.0
        static let SearchBBoxHalfHeight = 1.0
        static let SearchLatRange = (-90.0, 90.0)
        static let SearchLonRange = (-180.0, 180.0)
    }
    
    struct FlickrParameterkeys{
        static let Method = "method"
        static let APIKey = "api_key"
        static let Format = "format"
        static let NoJSONCallBack = "nojsoncallback"
        static let Extras = "extras"
        static let SafeSearch = "safe_search"
        static let BBox = "bbox"
        static let longitude = "lon"
        static let latitude = "lat"
    }
    
    struct FlickrParameterValues{
        static let Method = "flickr.photos.search"
        static let APIKey = "32e6458d2f3905864ea435e944193101"
        static let Format = "json"
        static let NoJSONCallBack = "1"
        static let MediumURL = "url_m"
        static let SafeSearch = "1"
    }
    
    struct FlickrResponseKeys{
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let Total = "total"
        static let MediumURL = "url_m"
    }
    
    struct FlickrResponseValues {
        static let OKStatus = "ok"
    }
}
