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
                        Label("Parts", systemImage: "batteryblock").tag(AppView.parts)
                        Label("Sets", systemImage: "shippingbox").tag(AppView.sets)
                    }.pickerStyle(SegmentedPickerStyle())
                }
                ToolbarItem(placement: .navigation) {
                    let showQueueButton = appManager.isLoading() || appManager.hasError()
                    if showQueueButton {
                        Button(action: {
                            showQueue = true
                        }) {
                            if appManager.hasError() {
                                Label("Status", systemImage: "exclamationmark.triangle")
                            } else {
                                ProgressView().scaleEffect(2/3)
                            }
                        }.popover(isPresented: $showQueue,
                                  arrowEdge: .bottom) {
                            AppOperationQueueView()
                        }
                    }
                }
                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        appManager.setActiveModal(.add)
                    }) {
                        switch appManager.activeTab {
                        case .parts: Label("Add Part", systemImage: "plus")
                        case .sets: Label("Add Set", systemImage: "plus")
                        }
                    }
                }
            }
            .searchable(text: $activeFilter, prompt: "Search")
        }.sheet(isPresented: $appManager.showModal) {
            switch appManager.activeTab {
            case .parts:
                switch appManager.activeModal {
                case .add:
                    AddPartView(isPresented: $appManager.showModal)
                        .frame(width: 350, height: 500, alignment: .center)
                case .addCustom:
                    AddCustomPartView(isPresented: $appManager.showModal)
                        .frame(width: 350, height: 500, alignment: .center)
                }
            case .sets:
                AddSetView(isPresented: $appManager.showModal)
                    .frame(width: 350, height: 500, alignment: .center)
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
