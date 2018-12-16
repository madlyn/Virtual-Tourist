//
//  DataController.swift
//  Virtual Tourist
//
//  Created by Lyn Almasri on 12/16/18.
//  Copyright © 2018 lynmasri. All rights reserved.
//

import Foundation
import CoreData

class DataController{
    let persistentContainer : NSPersistentContainer
    
    init(modelName : String){
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func load(complition: (()->Void)? = nil){
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else{
                fatalError(error!.localizedDescription)
            }
            complition?()
        }
    }
    
    var viewContext: NSManagedObjectContext{
        return persistentContainer.viewContext
    }
}
