//
//  ImageDownloader.swift
//  Virtual Tourist
//
//  Created by Lyn Almasri on 12/16/18.
//  Copyright © 2018 lynmasri. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class ImageDownloader{
    func downloadImage(url : String, completionHandler: @escaping ( _ data: Data?, _ error: String?) -> Void){
        
            do {
                let data = try Data(contentsOf: URL(string: url)! )
                completionHandler(data, nil)
                
                
            } catch{
                completionHandler(nil, "could not download image")
            }
        
    }
}
