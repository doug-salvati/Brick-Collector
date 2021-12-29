//
//  AddSetView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/27/21.
//

import SwiftUI

struct AddSetView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var manager: RebrickableManager
    @EnvironmentObject private var appManager: AppManager
    @Environment(\.managedObjectContext) private var viewContext
    @State private var input:String = ""
    @State private var suffix:String = "-1"
    @State private var secondPage:Bool = false
    private var searchString:String {
        "\(input)\(suffix)"
    }
    
    var body: some View {
        let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
        VStack {
            VStack {
                HStack {
                    Text("Add Set")
                        .font(.largeTitle)
                    Spacer()
                }
            }.padding(.bottom)
            if (!secondPage) {
                HStack {
                    TextField("Set ID", text: $input)
                    Picker("Suffix", selection: $suffix) {
                        Text("No Suffix").tag("")
                        ForEach(1..<31) { Text("-\($0)").tag("-\($0)") }
                    }.labelsHidden()
                    Button(action: {
                        Task {
                            await manager.searchSet(byId: searchString)
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
                        AsyncImage(url: URL(string: manager.searchedSet.result!.img)!)
                        HStack {
                            Text(manager.searchedSet.result!.id)
                                .fontWeight(.bold)
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
                        Text(manager.searchedSet.result!.id)
                            .fontWeight(.bold)
                        Spacer()
                        Text(manager.searchedSet.result!.name)
                    }
                    if (manager.searchedInventory.loading) {
                        ProgressView()
                    } else if (manager.searchedInventory.error != nil) {
                        Text(manager.searchedInventory.error!.localizedDescription)
                    } else {
                        let partCount = manager.searchedInventory.result!.reduce(0) { $0 + $1.quantity }
                        ScrollView {
                            LazyVGrid(columns: columns) {
                                ForEach(manager.searchedInventory.result!) { item in
                                    ZStack {
                                        AsyncImage(url: URL(string: item.part.img!)!)
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
                }
            }
            Spacer()
            HStack {
                Button(action:{
                    secondPage = false
                    isPresented = false
                    manager.resetSet()
                    manager.resetParts()
                }) {
                    Text("Cancel")
                }
                Spacer()
                if (!secondPage) {
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
                        manager.resetParts()
                    }) {
                        Text("Previous")
                    }
                    Button(action:{
                        appManager.upsertSet(manager.searchedSet.result!, containingParts: manager.searchedInventory.result!)
                        secondPage = false
                        isPresented = false
                        manager.resetSet()
                        manager.resetParts()
                    }) {
                        Text("Add Set")
                    }.disabled(manager.searchedInventory.result == nil)
                        .keyboardShortcut(.defaultAction)
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
