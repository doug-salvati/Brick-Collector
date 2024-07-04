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
    @State private var notes = ""
    private var quantityChange:Int64 {
        Int64(quantity) - set.quantity
    }
    @State private var showWarning = false
    @State private var showPopover = false
    @AppStorage("inventoryViewChoice") private var viewChoice:InventoryViewChoice = .icons
    
    var body: some View {
        let inventory = set.inventory!.allObjects as! [InventoryItem]
        HSplitView {
            VStack {
                HStack {
                    Button(action: {
                        withAnimation {
                            appManager.activeSetFeature = nil
                        }
                    }) {
                        Label("Close", systemImage: "xmark.circle.fill")
                    }.labelStyle(.iconOnly).buttonStyle(.borderless)
                        .keyboardShortcut(.cancelAction)
                    Spacer()
                    Button(action: {
                        showWarning = true
                    }) {
                        Label("Delete Set", systemImage: "trash").labelStyle(.iconOnly)
                    }.buttonStyle(.borderless).alert("Really delete \(set.name!)?", isPresented: $showWarning) {
                        Button("Cancel", role: .cancel) { }.keyboardShortcut(.cancelAction)
                        Button(role: .destructive, action: {
                            appManager.activeSetFeature = nil
                            appManager.delete(set: set)
                        }) {
                            Text("Delete")
                        }
                    }.keyboardShortcut(.delete, modifiers: [])
                }
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Stepper(value: $quantity, in: 1...(.max)) {
                                Text(String(quantity))
                            }.font(.title)
                            Button("Increase") {
                                quantity += 1
                            }.hidden().keyboardShortcut("]").frame(width:0)
                            Button("Decrease") {
                                quantity = max(1, quantity - 1)
                            }.hidden().keyboardShortcut("[").frame(width:0)
                            VStack(alignment: .leading) {
                                Text(set.name!).font(.title).textSelection(.enabled)
                                SetIdView(setId: set.id!, fontWeight: .bold)
                            }
                        }
                        Divider()
                        HStack {
                            Image(systemName: "tag")
                            Text(set.theme!).textSelection(.enabled)
                        }
                        HStack {
                            Image(systemName: "pencil.and.list.clipboard")
                            TextField("Notes", text: $notes)
                        }
                    }
                    Spacer()
                }
                Spacer()
                if set.img?.binary != nil {
                    Image(nsImage: NSImage(data: set.img!.binary!)!).resizable().scaledToFit()
                }
                if quantityChange != 0 || notes != set.notes ?? "" {
                    Button("Save") {
                        appManager.adjustQuantity(of: set, by: quantityChange)
                        appManager.setNotes(of: set, to: notes)
                    }.keyboardShortcut(.return, modifiers: []).padding()
                }
            }.padding().frame(minWidth: 200, maxWidth: 400, maxHeight: .infinity).layoutPriority(1)
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(set.partCount) parts").font(.title)
                        Text("\(inventory.count) unique").bold()
                    }
                    Spacer()
                    Picker(selection: $viewChoice, label: Text("View").hidden()) {
                        Image(systemName: "square.grid.2x2").tag(InventoryViewChoice.icons)
                        Image(systemName: "list.bullet").tag(InventoryViewChoice.list)
                    }.pickerStyle(SegmentedPickerStyle()).fixedSize()
                    if (set.missingFigs) {
                        Label("Set is missing minifigures.", systemImage: "person.crop.circle.badge.xmark").labelStyle(.iconOnly)                      .popover(isPresented: $showPopover) {
                            Text("Set is missing minifigures.").padding()
                        }.onHover { showPopover = $0}
                    }
                }
                SetInventoryView(inventory: inventory, style: viewChoice)
            }.padding().frame(minWidth: 200, maxWidth: 600, maxHeight: .infinity)
        }.onAppear {
            quantity = Int(set.quantity)
            notes = set.notes ?? ""
        }.onChange(of: set.quantity) { newQuantity in
            quantity = Int(newQuantity)
        }.onChange(of: set.notes) { newNotes in
            notes = newNotes ?? ""
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

