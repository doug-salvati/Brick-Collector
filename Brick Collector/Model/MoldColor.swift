//
//  PartColor.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/21/21.
//

import Foundation

struct MoldColor: Decodable {
    var colorId:Int
    var colorName:String
    var img:String
    var elements:[String]
    
    enum CodingKeys: String, CodingKey {
        case color_id, color_name, part_img_url, elements
    }
    
    init(from decoder:Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        colorId = try container.decode(Int.self, forKey: .color_id)
        colorName = try container.decode(String.self, forKey: .color_name)
        img = try container.decode(String.self, forKey: .part_img_url)
        elements = try container.decode([String].self, forKey: .elements)
    }
    
    init(colorId:Int, colorName:String, img:String, elements:[String]) {
        self.colorId = colorId
        self.colorName = colorName
        self.img = img
        self.elements = elements
    }
}
