//
//  SetFeatureView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/29/21.
//

import SwiftUI

struct SetFeatureView: View {
    @EnvironmentObject private var appManager: AppManager

    var set:Kit
    @State private var quantity = 0
    private var quantityChange:Int64 {
        Int64(quantity) - set.quantity
    }
    @State private var showWarning = false
    
    var body: some View {
        let inventory = set.inventory!.allObjects as! [InventoryItem]
        HSplitView {
            VStack {
                HStack {
                    Button("Close") {
                        withAnimation {
                            appManager.activeSetFeature = nil
                        }
                    }
                    if quantityChange != 0 {
                        Button("Save") {
                            appManager.adjustQuantity(of: set, by: quantityChange)
                        }
                    }
                    Spacer()
                    Button(action: {
                        showWarning = true
                    }) {
                        Label("Delete Set", systemImage: "trash").labelStyle(.iconOnly)
                    }.buttonStyle(.borderless).alert("Really delete \(set.name!)?", isPresented: $showWarning) {
                        Button("Cancel", role: .cancel) { }
                        Button(role: .destructive, action: {
                            appManager.activeSetFeature = nil
                            appManager.delete(set: set)
                        }) {
                            Text("Delete")
                        }
                    }
                }
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Stepper(value: $quantity, in: 1...(.max)) {
                                Text(String(quantity))
                            }.font(.title)
                            SetIdView(setId: set.id!, fontWeight: .bold)
                            Text(set.name!).font(.title2)
                        }
                        Text(set.theme!)
                    }
                    Spacer()
                }
                Spacer()
                if set.img != nil {
                    Image(nsImage: NSImage(data: set.img!)!).resizable().scaledToFit()
                }
            }.padding().frame(minWidth: 200, maxWidth: 400, maxHeight: .infinity).layoutPriority(1)
            VStack {
                Text("\(set.partCount) parts (\(inventory.count) unique)").fontWeight(.bold)
                SetInventoryView(inventory: inventory)
            }.padding().frame(minWidth: 200, maxWidth: 600, maxHeight: .infinity)
        }.onAppear {
            quantity = Int(set.quantity)
        }.onChange(of: set.quantity) { newQuantity in
            quantity = Int(newQuantity)
        }
    }
}

struct SetFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let set = try! context.fetch(Kit.fetchRequest()).first
        let manager = RebrickableManagerPreview()
        SetFeatureView(set: set!).environmentObject(AppManager(using: manager))
    }
}
