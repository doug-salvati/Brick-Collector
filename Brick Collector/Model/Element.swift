//
//  Part.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/4/21.
//

import Foundation

struct Element: Decodable {
    var id:String
    var img:String
    var name:String
    var colorId:Int
    
    enum CodingKeys: String, CodingKey {
        case element_id, part_img_url, part, color
    }
    
    enum PartCodingKeys: String, CodingKey {
        case name
    }
    
    enum ColorCodingKeys: String, CodingKey {
        case id
    }
    
    init(from decoder:Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .element_id)
        img = try container.decode(String.self, forKey: .part_img_url)
        let part = try container.nestedContainer(keyedBy: PartCodingKeys.self, forKey: .part)
        name = try part.decode(String.self, forKey: .name)
        let color = try container.nestedContainer(keyedBy: ColorCodingKeys.self, forKey: .color)
        colorId = try color.decode(Int.self, forKey: .id)
    }
    
    init(id:String, img:String, name:String, colorId:Int) {
        self.id = id
        self.img = img
        self.name = name
        self.colorId = colorId
    }
}
