//
//  File.swift
//  
//
//  Created by Rick Gigger on 1/7/20.
//

import Foundation
import SwiftLMDB

class DictCollection: SimpleCollection {
   let name: String
   var docs: [String:Data] = [:]
   init(_ name: String) {
       self.name = name
   }
   func set(key: String, data: Data) {
       self.docs[key] = data
   }
   func get(key: String) -> Data? {
       return self.docs[key]
   }
   func delete(key: String) {
       self.docs.removeValue(forKey: key)
   }
   func each(_ cb: (String, Data) -> Bool) {
       for (key, data) in self.docs {
           let keepGoing = cb(key, data)
           if(!keepGoing) { break }
       }
   }
   func empty() throws {
       docs = [:]
   }
}
