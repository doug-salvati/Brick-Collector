//
//  IOSet.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/4/22.
//

import Foundation

struct IOSet: Codable {
    var id:String
    var name:String
    var partCount:Int
    var theme:String
    var img:Data?
    var quantity:Int
    var missingFigs:Bool?
    var notes:String?
    
    init(kit:Kit) {
        id = kit.id ?? ""
        name = kit.name ?? ""
        partCount = Int(kit.partCount)
        theme = kit.theme ?? ""
        img = kit.img?.binary
        quantity = Int(kit.quantity)
        missingFigs = kit.missingFigs
        notes = kit.notes
    }
}
