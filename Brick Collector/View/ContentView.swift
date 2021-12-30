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
    
    @State private var showModal = false
    @State private var showQueue = false
    
    var body: some View {
        VStack {
            VStack {
                switch appManager.activeTab {
                    case .parts: PartListView()
                    case .sets: SetListView()
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
                                  attachmentAnchor: .point(.bottom),
                                  arrowEdge: .bottom) {
                            AppOperationQueueView()
                        }
                    }
                }
                ToolbarItem {
                    Button(action: {
                        showModal = true
                    }) {
                        switch appManager.activeTab {
                        case .parts: Label("Add Part", systemImage: "plus")
                        case .sets: Label("Add Set", systemImage: "plus")
                        }
                    }
                }
            }
        }.sheet(isPresented: $showModal) {
            switch appManager.activeTab {
            case .parts:
                AddPartView(isPresented: $showModal)
                    .frame(width: 300, height: 500, alignment: .center)
            case .sets:
                AddSetView(isPresented: $showModal)
                    .frame(width: 300, height: 500, alignment: .center)
            }
        }.frame(width: 800, height: 500, alignment: .center)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext).environmentObject(AppManager(using: manager))
    }
}
