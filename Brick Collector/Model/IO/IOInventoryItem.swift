//
//  IOInventoryItem.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/4/22.
//

import Foundation

struct IOInventoryItem: Codable {
    var setId:String
    var partId:String
    var quantity:Int
    
    init(item:InventoryItem) {
        setId = item.kit?.id ?? ""
        partId = item.part?.id ?? ""
        quantity = Int(item.quantity)
    }
}
