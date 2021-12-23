//
//  Mold.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/21/21.
//

import Foundation

struct Mold: Decodable {
    var partNum:String
    var name:String
    
    enum CodingKeys: String, CodingKey {
        case part_num, name
    }
    
    init(from decoder:Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        partNum = try container.decode(String.self, forKey: .part_num)
        name = try container.decode(String.self, forKey: .name)
    }
    
    init(partNum:String, name:String) {
        self.partNum = partNum
        self.name = name
    }
}
