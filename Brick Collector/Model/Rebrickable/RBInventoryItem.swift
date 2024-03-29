//
//  Inventory.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/24/21.
//

import Foundation

struct RBInventoryItem: Decodable, Identifiable {
    var part:RBMold
    var color:RBElementColor
    var elementId:String?
    var quantity:Int
    var isSpare:Bool
    var isMinifig:Bool
    var id:String {
        elementId ?? "\(part.partNum) (\(color.rebrickableName))"
    }
    
    enum CodingKeys: String, CodingKey {
        case part, color, element_id, quantity, is_spare
    }
    
    init(from decoder:Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        part = try container.decode(RBMold.self, forKey: .part)
        color = try container.decode(RBElementColor.self, forKey: .color)
        elementId = try? container.decode(String.self, forKey: .element_id)
        quantity = try container.decode(Int.self, forKey: .quantity)
        isSpare = try container.decode(Bool.self, forKey: .is_spare)
        isMinifig = false
    }
    
    init(part:RBMold, color:RBElementColor, elementId:String?, quantity:Int, isSpare:Bool, isMinifig:Bool = false) {
        self.part = part
        self.color = color
        self.elementId = elementId
        self.quantity = quantity
        self.isSpare = isSpare
        self.isMinifig = isMinifig
    }
}

struct MinifigInventoryItem: Decodable {
    var setNum:String
    var quantity:Int
    
    enum CodingKeys: String, CodingKey {
        case set_num, quantity
    }
    
    init(from decoder:Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        setNum = try container.decode(String.self, forKey: .set_num)
        quantity = try container.decode(Int.self, forKey: .quantity)
    }
}
