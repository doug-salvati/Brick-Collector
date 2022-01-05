//
//  IOCollection.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/4/22.
//

import Foundation

struct IOCollection: Codable {
    static var emptyCollection = IOCollection(parts: [], sets: [], inventories: [])
    
    var parts:[IOPart]
    var sets:[IOSet]
    var inventories:[IOInventoryItem]
    
    init(parts:[Part], sets:[Kit], inventories:[InventoryItem]) {
        self.parts = parts.map(IOPart.init)
        self.sets = sets.map(IOSet.init)
        self.inventories = inventories.map(IOInventoryItem.init)
    }
}
