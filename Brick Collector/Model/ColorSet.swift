//
//  ColorSet.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/8/21.
//

import Foundation

enum ColorSet: String, CaseIterable, Identifiable {
    case official = "Official"
    case bricklink = "BrickLink"
    case rebrickable = "Rebrickable"
    
    var id: ColorSet {
        return self
    }
}
