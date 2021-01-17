//
//  ElementColor.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/8/21.
//

import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        var r:Double = 0
        var g:Double = 0
        var b:Double = 0
        let scanner = Scanner(string: hex)
        var hexNumber:UInt64 = 0
        if scanner.scanHexInt64(&hexNumber) {
            r = Double((hexNumber & 0xff0000) >> 16) / 255
            g = Double((hexNumber & 0xff0000) >> 8) / 255
            b = Double(hexNumber & 0xff0000) / 255
        }
        self.init(red: r, green: g, blue: b)
    }
}

struct ElementColor: Decodable {
    var id:Int
    var hex:String
    var name:String?
    var rebrickableName:String?
    var bricklinkName:String?
    var rgb:Color {
        return Color(hex)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, rgb, name, external_ids
    }
    
    enum ExternalIdCodingKeys: String, CodingKey {
        case BrickLink, LEGO
    }
    
    enum VendorCodingKey: String, CodingKey {
        case ext_descrs
    }
    
    init(from decoder:Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        hex = try container.decode(String.self, forKey: .rgb)
        rebrickableName = try? container.decode(String.self, forKey: .name)
        let externalIds = try container.nestedContainer(keyedBy: ExternalIdCodingKeys.self, forKey: .external_ids)
        let official = try? externalIds.nestedContainer(keyedBy: VendorCodingKey.self, forKey: .LEGO)
        if official != nil {
            name = try? official!.decode([[String]].self, forKey: .ext_descrs)[0][0]
        }
        let bricklink = try? externalIds.nestedContainer(keyedBy: VendorCodingKey.self, forKey: .BrickLink)
        if bricklink != nil {
            bricklinkName = try? bricklink!.decode([[String]].self, forKey: .ext_descrs)[0][0]
        }
    }
    
    init(
        id:Int,
        hex:String,
        name:String,
        rebrickableName:String,
        bricklinkName:String
    ) {
        self.id = id
        self.hex = hex
        self.name = name
        self.rebrickableName = rebrickableName
        self.bricklinkName = bricklinkName
    }
}
