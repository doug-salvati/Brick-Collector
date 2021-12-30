//
//  SetInventoryView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/29/21.
//

import SwiftUI

struct SetInventoryView: View {
    @EnvironmentObject private var appManager: AppManager
    var inventory:[InventoryItem]
    
    var body: some View {
        List {
            ForEach(inventory) { item in
                HStack {
                    Text("\(item.quantity)x \(item.part!.id!)")
                    Button("GO") {
                        appManager.activeTab = .parts
                        appManager.activePartFeature = item.part!
                    }
                }
            }
        }
    }
}

struct SetInventoryView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        SetInventoryView(inventory: []).environmentObject(AppManager(using: manager))
    }
}
