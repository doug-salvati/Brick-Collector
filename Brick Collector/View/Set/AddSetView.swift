//
//  AddSetView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/27/21.
//

import SwiftUI

enum AddSetMethod: String {
    case byID = "byID"
    case bySearchQuery = "bySearchQuery"
}

struct AddSetView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var manager: RebrickableManager
    @EnvironmentObject private var appManager: AppManager
    @Environment(\.managedObjectContext) private var viewContext
    @State private var input:String = ""
    @State private var suffix:String = "-1"
    @State private var method:AddSetMethod = AddSetMethod(rawValue: UserDefaults.standard.string(forKey: "defaultAddSetMethod") ?? "byID") ?? .byID
    @State private var secondPage:Bool = false
    @State private var spares:Bool = false
    @State private var includeFigs:Bool = true
    private var searchString:String {
        "\(input)\(suffix)"
    }
    
    private static var placeholders: [AddSetMethod : String] = [
        .byID: "Set ID",
        .bySearchQuery: "Search",
    ]
    
    func search() async {
        switch method {
        case .byID:
            await manager.searchSet(byId: searchString)
        case .bySearchQuery:
            await manager.searchSet(bySearchQuery: input)
        }
    }
    
    var body: some View {
        let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
        let hasMinifigs: Bool = manager.searchedInventory.result?.contains(where: {$0.isMinifig}) ?? false
        let inventory: [RBInventoryItem] = (manager.searchedInventory.result ?? []).filter {
            includeFigs || !$0.isMinifig
        }
        VStack {
            VStack {
                HStack {
                    Text("Add Set")
                        .font(.largeTitle)
                    Spacer()
                }
                Picker(selection: $method, label: Text("by:")) {
                    Text("ID").tag(AddSetMethod.byID)
                    Text("Name").tag(AddSetMethod.bySearchQuery)
                }.pickerStyle(SegmentedPickerStyle()).onChange(of: method) { method in
                    manager.resetSet()
                }
            }.padding(.bottom)
            if (!secondPage) {
                HStack {
                    TextField(AddSetView.placeholders[method]!, text: $input).onSubmit {
                        Task {
                            await search()
                        }
                    }
                    if method == .byID {
                        Picker("Suffix", selection: $suffix) {
                            Text("No Suffix").tag("")
                            ForEach(1..<31) { Text("-\($0)").tag("-\($0)") }
                        }.labelsHidden()
                    }
                    Button(action: {
                        Task {
                            await search()
                        }
                    }) {
                        Text("Search")
                    }.disabled(input.isEmpty)
                }
                Spacer()
                if manager.searchedSet.loading {
                    ProgressView()
                } else if manager.searchedSet.result != nil {
                    VStack {
                        if manager.searchedSet.result!.img == nil {
                            Image(systemName: "photo")
                            Text("No Image Available")
                        } else {
                            AsyncImage(url: URL(string: manager.searchedSet.result!.img!)!)
                        }
                        HStack {
                            SetIdView(setId: manager.searchedSet.result!.id, fontWeight: .bold)
                            Spacer()
                            Text(manager.searchedSet.result!.name)
                        }
                    }
                } else {
                    Text(manager.searchedSet.error?.localizedDescription ?? "Enter Search")
                }
            } else {
                VStack {
                    Text("Review Parts")
                        .font(.title)
                    HStack {
                        SetIdView(setId: manager.searchedSet.result!.id, fontWeight: .bold)
                        Spacer()
                        Text(manager.searchedSet.result!.name)
                    }
                    if (manager.searchedInventory.loading) {
                        ProgressView()
                    } else if (manager.searchedInventory.error != nil) {
                        Text(manager.searchedInventory.error!.localizedDescription)
                    } else {
                        let partCount = inventory.reduce(0) { $0 + $1.quantity }
                        ScrollView {
                            LazyVGrid(columns: columns) {
                                ForEach(inventory) { item in
                                    ZStack {
                                        if (item.part.img != nil) {
                                            AsyncImage(url: URL(string: item.part.img!)!)
                                        } else {
                                            Image(systemName: "photo")
                                        }
                                        VStack {
                                            Spacer()
                                            HStack {
                                                Text("\(item.quantity)x").fontWeight(.bold).colorInvert()
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                            Text("\(partCount) Parts").font(.footnote).padding()
                        }
                    }
                    if (!spares && hasMinifigs) {
                        HStack {
                            Toggle(isOn: $includeFigs) {
                                Text("Include Minifigures")
                            }
                            Spacer()
                        }.padding(.top).padding(.bottom)
                    }
                }
            }
            Spacer()
            VStack {
                HStack {
                    Button(action:{
                        secondPage = false
                        isPresented = false
                        manager.resetSet()
                        manager.resetParts()
                    }) {
                        Text("Cancel")
                    }
                    .keyboardShortcut(.cancelAction)
                    Spacer()
                    if (!secondPage) {
                        Button(action:{
                            Task {
                                secondPage = true
                                spares = true
                                await manager.searchInventory(bySetId: manager.searchedSet.result!.id, spares: true)
                            }
                        }) {
                            Text("Add Spares")
                        }.disabled(manager.searchedSet.result == nil)
                        Button(action:{
                            Task {
                                secondPage = true
                                await manager.searchInventory(bySetId: manager.searchedSet.result!.id)
                            }
                        }) {
                            Text("Next")
                        }.disabled(manager.searchedSet.result == nil)
                            .keyboardShortcut(.defaultAction)

                    } else {
                        Button(action:{
                            secondPage = false
                            spares = false
                            manager.resetParts()
                        }) {
                            Text("Previous")
                        }
                        Button(action:{
                            if spares {
                                appManager.upsertSpares(spares: inventory)
                            } else {
                                appManager.upsertSet(manager.searchedSet.result!, containingParts: inventory, missingFigs: !includeFigs)
                            }
                            secondPage = false
                            isPresented = false
                            manager.resetSet()
                            manager.resetParts()
                        }) {
                            Text(spares ? "Add Spare Parts" : "Add Set")
                        }.disabled(manager.searchedInventory.result == nil)
                            .keyboardShortcut(.defaultAction)
                    }
                }
            }
        }.padding()
    }
}

struct AddSetView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        AddSetView(isPresented: .constant(true))
            .environmentObject(manager as RebrickableManager)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
