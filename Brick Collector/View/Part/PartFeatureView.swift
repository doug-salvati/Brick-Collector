//
//  PartFeatureView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/29/21.
//

import SwiftUI

struct PartFeatureView: View {
    @EnvironmentObject private var appManager: AppManager

    var part:Part
    @State private var quantity = 0
    
    var body: some View {
        let looseCount = part.loose
        let setCount = part.quantity - part.loose
        let usages = part.usages!.allObjects as! [InventoryItem]
        let usageCount = usages.reduce(0) { $0 + $1.quantity }
        HSplitView {
            VStack {
                HStack {
                    Button("Back") {
                        withAnimation {
                            appManager.activePartFeature = nil
                        }
                    }
                    Spacer()
                }
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Stepper(value: $quantity, in: Int(setCount)...(.max)) {
                                Text(String(quantity))
                            }.font(.title)
                            Text(part.name!).font(.title2)
                        }
                        Text("Element #\(part.id!)").italic()
                        ColorNameView(colorId: Int(part.colorId))
                    }
                    Spacer()
                }
                Spacer()
                if part.img != nil {
                    Image(nsImage: NSImage(data: part.img!)!).resizable().scaledToFit()
                }
            }.padding().frame(minWidth: 200, maxWidth: 400, maxHeight: .infinity).layoutPriority(1)
            VStack {
                Text("\(setCount)x from \(usageCount) set\(usageCount == 1 ? "" : "s")").fontWeight(.bold)
                Text("\(looseCount)x loose").fontWeight(.bold)
                PartInventoryView(inventory: usages)
            }.padding().frame(minWidth: 200, maxWidth: 600, maxHeight: .infinity)
        }.onAppear {
            quantity = Int(part.quantity)
        }
    }
}

struct PartFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let part = try! context.fetch(Part.fetchRequest()).first
        let manager = RebrickableManagerPreview()
        PartFeatureView(part: part!).environmentObject(AppManager(using: manager))
    }
}
