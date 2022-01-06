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
        let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(inventory) { usage in
                    let set = usage.kit!
                    Button(action: {
                        appManager.activeTab = .sets
                        appManager.activeSetFeature = set
                    }) {
                        ZStack {
                            Rectangle().aspectRatio(1, contentMode: .fill).foregroundColor(.white)
                            if set.img != nil {
                                Image(nsImage: NSImage(data: set.img!)!).resizable().scaledToFit().padding()
                            } else {
                                Image(systemName: "photo").foregroundColor(.black)
                            }
                            VStack {
                                Spacer()
                                HStack {
                                    let setQuantity = usage.kit!.quantity
                                    let suffix = setQuantity > 1 ? " (\(setQuantity))" : ""
                                    Text("\(usage.quantity)x in \(set.id!)\(suffix)").fontWeight(.bold).colorInvert().padding()
                                    Spacer()
                                }
                            }
                        }.clipped().aspectRatio(1, contentMode: .fit)
                    }.buttonStyle(.plain)
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
