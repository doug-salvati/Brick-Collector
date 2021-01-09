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
    
    enum CodingKeys: String, CodingKey {
        case element_id, part_img_url, part
    }
    
    enum PartCodingKeys: String, CodingKey {
        case name
    }
    
    init(from decoder:Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .element_id)
        img = try container.decode(String.self, forKey: .part_img_url)
        let part = try container.nestedContainer(keyedBy: PartCodingKeys.self, forKey: .part)
        name = try part.decode(String.self, forKey: .name)
    }
    
    init(id:String, img:String, name:String) {
        self.id = id;
        self.img = img;
        self.name = name;
    }
}
