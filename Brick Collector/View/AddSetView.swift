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
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("Add Set")
                        .font(.largeTitle)
                    Spacer()
                }
            }.padding(.bottom)
            
            HStack {
                TextField("Set ID", text: $input)
                Button(action: {
                    Task {
                        // TODO: Search set
                    }
                }) {
                    Text("Search")
                }.disabled(input.isEmpty)
            }
            Spacer()
//            if manager.searchedParts.loading {
//                ProgressView()
//            } else if manager.searchedParts.result != nil {
//                PartSelectionView(parts: (manager.searchedParts.result)!, selections: $selections)
//            } else {
//                Text(manager.searchedParts.error?.localizedDescription ?? "Enter Search")
//            }
            Spacer()
            HStack {
                Button(action:{
                    // TODO: reset search
                    isPresented = false
                }) {
                    Text("Cancel")
                }
                Spacer()
                Button(action:{
//                    appManager.upsertParts(elements: getSelections())
//                    manager.resetParts()
                    isPresented = false
                }) {
                    Text("Next")
                }
                .disabled(true)
                .keyboardShortcut(.defaultAction)
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
