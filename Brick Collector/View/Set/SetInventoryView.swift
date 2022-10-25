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
    @AppStorage("partSort")
    private var partSort:PartSortOption = .color
    
    private func getSortMethod() -> (InventoryItem, InventoryItem) -> Bool {
        switch partSort {
        case .color:
            return {$0.part?.colorId ?? 0 < $1.part?.colorId ?? 0}
        case .name:
            return {$0.part?.name ?? "" < $1.part?.name ?? ""}
        case .quantityDown:
            return {$0.quantity > $1.quantity}
        case .quantityUp:
            return {$0.quantity < $1.quantity}
        }
    }
    
    var body: some View {
        let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(inventory.sorted(by: getSortMethod())) { item in
                    let part = item.part!
                    Button(action: {
                        appManager.activeTab = .parts
                        appManager.activePartFeature = part
                    }) {
                        ZStack {
                            Rectangle().aspectRatio(1, contentMode: .fill).foregroundColor(.white)
                            if part.img != nil {
                                Image(nsImage: NSImage(data: part.img!)!).resizable().scaledToFit().padding()
                            } else {
                                Image(systemName: "photo").foregroundColor(.black)
                            }
                            VStack {
                                Spacer()
                                HStack {
                                    Text("\(item.quantity)x").fontWeight(.bold).colorInvert().padding()
                                    Spacer()
                                }
                            }
                        }.clipped().aspectRatio(1, contentMode: .fit)
                    }
                }
            }.buttonStyle(.plain)
        }
    }
}

struct SetInventoryView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        SetInventoryView(inventory: []).environmentObject(AppManager(using: manager))
    }
}
