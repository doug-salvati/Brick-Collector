//
//  PartInventoryView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/29/21.
//

import SwiftUI

struct PartInventoryView: View {
    @EnvironmentObject private var appManager: AppManager
    var inventory:[InventoryItem]
    
    var body: some View {
        List {
            ForEach(inventory) { usage in
                HStack {
                    Text("\(usage.quantity)x in \(usage.kit!.id!)")
                    Button("GO") {
                        appManager.activeTab = .sets
                        appManager.activePartFeature = nil
                        appManager.activeSetFeature = usage.kit!
                    }
                }
            }
        }
    }
}

struct PartInventoryView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        PartInventoryView(inventory: []).environmentObject(AppManager(using: manager))
    }
}
