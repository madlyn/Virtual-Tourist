//
//  FlickrWebManager.swift
//  Virtual Tourist
//
//  Created by Lyn Almasri on 12/16/18.
//  Copyright © 2018 lynmasri. All rights reserved.
//

import Foundation

class FlickrWebManager{
    public func displayImageFromFlickrBySearch(lat : Double , long: Double, completionHandler: @escaping (_ result: [[String:AnyObject]]?, _ error: String?) -> Void) {
        
        let methodParameters: [String: AnyObject] = [Constants.FlickrParameterKeys.SafeSearch:Constants.FlickrParameterValues.UseSafeSearch,
                                                     Constants.FlickrParameterKeys.BoundingBox : bboxString(lat: lat, long: long),
                                                     Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.MediumURL,
                                                     Constants.FlickrParameterKeys.APIKey : Constants.FlickrParameterValues.APIKey,
                                                     Constants.FlickrParameterKeys.Method : Constants.FlickrParameterValues.SearchMethod,
                                                     Constants.FlickrParameterKeys.Format : Constants.FlickrParameterValues.ResponseFormat,
                                                     Constants.FlickrParameterKeys.PerPage : 21,
                                                     Constants.FlickrParameterKeys.NoJSONCallback : Constants.FlickrParameterValues.DisableJSONCallback] as! [String: AnyObject]
        
        let session = URLSession.shared
        let request = URLRequest(url: self.flickrURLFromParameters(methodParameters))
        let task = session.dataTask(with: request) { (data, response, error) in
            
            guard error == nil else{
                completionHandler(nil, "There was an error with your request: \(error)")
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                completionHandler(nil,"Your request returned a status code other than 2xx!")
                return
            }
            guard let data = data else{
                completionHandler(nil,"No data was returned by the request!")
                return
            }
            var parsedResults = [String : AnyObject]()
            do{
                parsedResults = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : AnyObject]
                
            } catch{
                completionHandler(nil,"There was an error parsing JSON")
                return
            }
            guard let stat = parsedResults[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                completionHandler(nil,"Flickr API returned an error. See error code and message in \(parsedResults)")
                return
            }
            
            guard let photos = parsedResults["photos"] as? [String : AnyObject] else {
                completionHandler(nil,"No photos parsed")
                return
            }
            
            print(parsedResults)
            
            
            guard let photoDictionary = photos["photo"] as? [[String : AnyObject]] else{
                completionHandler(nil,"No Photos")
                return
            }
            
            var resultPhotos = [[String : AnyObject]]()
            
            for photo in photoDictionary{
                var tempPhoto = [String : AnyObject]()
                if let id = photo["id"] as? Int, let url = photo["url_m"]{
                    tempPhoto["id"] = id as AnyObject
                    tempPhoto["url"] = url
                }else{
                    completionHandler(nil,"Could not retrieve photo id")
                    return
                }
                
                
                
            }
            
            
            //            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoDictionary.count)))
            //            guard let url = photoDictionary [randomPhotoIndex]["url_m"] as? String else{
            //                displayError("Missing URL")
            //                return
            //            }
            //            do {
            //                let data = try Data(contentsOf: URL(string: url)! )
            //                performUIUpdatesOnMain {
            //                     self.photoImageView.image = UIImage(data: data)
            //                    self.photoTitleLabel.text = photoDictionary[randomPhotoIndex]["title"] as! String
            //                    self.setUIEnabled(true)
            //                }
            //
            //
            //
            //            } catch{
            //                displayError("Data not retrieved from URL")
            //            }
            
            
            
            //            self.displayImageFromFlickrBySearchWithPageNumber(methodParameters: methodParameters, pagenumber: randomPageNumber)
        }
        task.resume()
    }
    
    
    private func flickrURLFromParameters(_ parameters: [String: AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    private func bboxString(lat : Double, long :Double)->String{
        let minLat = max(lat - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let minLong = max(long - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let maxLat = min(lat + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        let maxLong = min(long + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        
        return "\(minLong),\(minLat),\(maxLong),\(maxLat)"
    }
    
}
