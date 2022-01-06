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

func consolidate(inventory:[RBInventoryItem]) -> [RBInventoryItem] {
    var result:[RBInventoryItem] = []
    inventory.forEach { item in
        if let index = result.firstIndex(where: { $0.id == item.id }) {
            var repeatItem = result[index]
            result.remove(at: index)
            repeatItem.quantity += item.quantity
            result.append(repeatItem)
        } else {
            result.append(item)
        }
    }
    return result
}
