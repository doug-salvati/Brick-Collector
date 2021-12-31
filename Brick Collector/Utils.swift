//
//  Utils.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/30/21.
//

import Foundation

extension String {
    func filterable() -> String {
        return self.lowercased().replacingOccurrences(of: " ", with: "")
    }
}
