//
//  PartInventoryView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/29/21.
//

import SwiftUI

struct PartInventoryView: View {
    var inventory:[InventoryItem]
    
    var body: some View {
        List {
            ForEach(inventory) { usage in
                Text("\(usage.quantity)x in \(usage.kit!.id!)")
            }
        }
    }
}

struct PartInventoryView_Previews: PreviewProvider {
    static var previews: some View {
        PartInventoryView(inventory: [])
    }
}
