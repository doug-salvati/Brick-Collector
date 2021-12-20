//
//  ContentView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/3/21.
//

import SwiftUI
import CoreData

enum AppView {
    case sets
    case parts
}

struct ContentView: View {
    @EnvironmentObject private var appManager: AppManager
    
    @State private var showModal = false
    @State private var showQueue = false
    @State private var activeView: AppView = .parts
    
    var body: some View {
        VStack {
            VStack {
                switch activeView {
                    case .parts: PartListView()
                    case .sets: Text("Sets")
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker(selection: $activeView, label: Text("View")) {
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
                        Label("Add Part", systemImage: "plus")
                    }
                }
            }
        }.sheet(isPresented: $showModal) {
            AddPartView(isPresented: $showModal)
                .frame(width: 300, height: 300, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
        }.frame(width: 800, height: 500, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext).environmentObject(AppManager(using: manager))
    }
}
