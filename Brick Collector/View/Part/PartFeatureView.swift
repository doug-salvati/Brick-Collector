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
    private var quantityChange:Int64 {
        Int64(quantity) - part.quantity
    }
    @State private var showWarning = false
    @State private var showTooltip = false
    
    var body: some View {
        let looseCount = part.loose
        let setCount = part.quantity - part.loose
        let usages = part.usages!.allObjects as! [InventoryItem]
        let usageCount = usages.reduce(0) { $0 + (($1.kit?.quantity) ?? 0) }
        HSplitView {
            VStack {
                HStack {
                    Button("Close") {
                        withAnimation {
                            appManager.activePartFeature = nil
                        }
                    }.keyboardShortcut(.cancelAction)
                    if quantityChange != 0 {
                        Button("Save") {
                            appManager.adjustQuantity(of: part, by: quantityChange)
                        }
                    }
                    Spacer()
                    Button(action: {
                        showWarning = true
                    }) {
                        Label("Delete Part", systemImage: "trash").labelStyle(.iconOnly)
                    }.buttonStyle(.borderless).alert("Really delete \(part.name!)?", isPresented: $showWarning) {
                        Button("Cancel", role: .cancel) { }.keyboardShortcut(.cancelAction)
                        Button(role: .destructive, action: {
                            appManager.activePartFeature = nil
                            appManager.delete(part: part)
                        }) {
                            Text("Delete")
                        }
                    }.disabled(part.quantity > part.loose)
                        .popover(isPresented: $showTooltip) {
                            Text("Part must not be used in any sets to be deleted.").padding()
                        }.onHover { showTooltip = $0 && part.quantity > part.loose}
                        .keyboardShortcut("D")
                }
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Stepper(value: $quantity, in: max(Int(setCount),1)...(Int.max)) {
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
        }.onChange(of: part.quantity) { newQuantity in
            quantity = Int(newQuantity)
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
