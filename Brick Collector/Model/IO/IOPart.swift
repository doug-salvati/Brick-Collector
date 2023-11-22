//
//  IOPart.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/4/22.
//

import Foundation

struct IOPart: Codable {
    var id:String
    var name:String
    var quantity:Int
    var loose:Int
    var colorId:Int
    var img:Data?
    var notes:String?
    
    init(part:Part) {
        id = part.id ?? ""
        name = part.name ?? ""
        quantity = Int(part.quantity)
        loose = Int(part.loose)
        colorId = Int(part.colorId)
        img = part.img?.binary
        notes = part.notes
    }
}
