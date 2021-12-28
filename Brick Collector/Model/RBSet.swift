//
//  RBSet.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/27/21.
//

import Foundation

struct RBSet: Decodable {
    var id:String
    var name:String
    var themeId:Int
    var partCount:Int
    var img:String
    var theme:String?
    
    enum CodingKeys: String, CodingKey {
        case set_num, name, theme_id, num_parts, set_img_url
    }
    
    init(from decoder:Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .set_num)
        name = try container.decode(String.self, forKey: .name)
        themeId = try container.decode(Int.self, forKey: .theme_id)
        partCount = try container.decode(Int.self, forKey: .num_parts)
        img = try container.decode(String.self, forKey: .set_img_url)
    }
}
