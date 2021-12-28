//
//  RBTheme.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/27/21.
//

import Foundation

struct RBTheme: Decodable {
    var id:Int
    var name:String
    enum CodingKeys: String, CodingKey {
        case id, name
    }
    
    init(from decoder:Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
    }
}
