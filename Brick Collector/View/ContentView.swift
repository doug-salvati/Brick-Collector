//
//  ContentView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/3/21.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject private var appManager: AppManager
    
    @State private var showQueue = false
    @State private var focusFilter = false
    @State private var activeFilter = ""
    
    @AppStorage("homepage")
    private var homepage:AppView = .parts
    
    var body: some View {
        VStack {
            VStack {
                switch appManager.activeTab {
                case .parts: PartListView(filter: activeFilter)
                case .sets: SetListView(filter: activeFilter)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker(selection: $appManager.activeTab, label: Text("View")) {
                        Text("Parts").tag(AppView.parts)
                        Text("Sets").tag(AppView.sets)
                    }.pickerStyle(SegmentedPickerStyle())
                }
                ToolbarItem {
                    Spacer()
                }
                ToolbarItem {
                    let showQueueButton = appManager.isLoading() || appManager.hasError()
                    if showQueueButton {
                        Button(action: {
                            showQueue = true
                        }) {
                            if appManager.hasError() {
                                Label("Status", systemImage: "exclamationmark.triangle")
                            } else {
                                ProgressView().scaleEffect(2/3).offset(x: 0, y: -4)
                            }
                        }.popover(isPresented: $showQueue,
                                  arrowEdge: .bottom) {
                            AppOperationQueueView()
                        }
                    }
                }
                ToolbarItem {
                    ZStack {
                        TextField("Filter", text: $activeFilter
                        ).textFieldStyle(.roundedBorder).frame(width: 200)
                        if (!activeFilter.isEmpty) {
                        HStack {
                            Spacer()
                                Button(action: {
                                    activeFilter = ""
                                }) {
                                    Label("Clear Filter", systemImage: "xmark.circle.fill").padding(8)
                                }.buttonStyle(.borderless)
                            }
                        }
                    }
                }
                ToolbarItem {
                    Button(action: {
                        appManager.showAdditionModal = true
                    }) {
                        switch appManager.activeTab {
                        case .parts: Label("Add Part", systemImage: "plus")
                        case .sets: Label("Add Set", systemImage: "plus")
                        }
                    }
                }
            }
        }.sheet(isPresented: $appManager.showAdditionModal) {
            switch appManager.activeTab {
            case .parts:
                AddPartView(isPresented: $appManager.showAdditionModal)
                    .frame(width: 300, height: 500, alignment: .center)
            case .sets:
                AddSetView(isPresented: $appManager.showAdditionModal)
                    .frame(width: 300, height: 500, alignment: .center)
            }
        }.onAppear {
            if homepage != .parts {
                DispatchQueue.main.async {
                    appManager.activeTab = homepage
                }
            }
        }
        .frame(idealWidth: 800, idealHeight: 500, alignment: .center)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext).environmentObject(AppManager(using: manager))
    }
}
