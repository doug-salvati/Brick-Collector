//
//  Mold.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/21/21.
//

import Foundation

struct RBMold: Decodable {
    var partNum:String
    var name:String
    var img:String? // included on set inventory requests
    
    enum CodingKeys: String, CodingKey {
        case part_num, name, part_img_url
    }
    
    init(from decoder:Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        partNum = try container.decode(String.self, forKey: .part_num)
        name = try container.decode(String.self, forKey: .name)
        img = try? container.decode(String.self, forKey: .part_img_url)
    }
    
    init(partNum:String, name:String) {
        self.partNum = partNum
        self.name = name
    }
}
