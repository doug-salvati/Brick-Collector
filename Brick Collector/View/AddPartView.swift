//
//  AddPartView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/3/21.
//

import SwiftUI

enum AddPartMethod: String {
    case byElement = "byElement"
    case byMoldAndColor = "byMoldAndColor"
    case bySet = "bySet"
}

let placeholders: [AddPartMethod : String] = [
    .byElement: "Element ID",
    .byMoldAndColor: "Part ID",
    .bySet: "Set ID"
]

struct AddPartView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var manager: RebrickableManager
    @EnvironmentObject private var appManager: AppManager
    @Environment(\.managedObjectContext) private var viewContext
    @State private var input:String = ""
    @State private var method:AddPartMethod = AddPartMethod(rawValue: UserDefaults.standard.string(forKey: "defaultAddPartMethod")!) ?? .byElement
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("Add Part")
                        .font(.largeTitle)
                    Spacer()
                }
                Picker(selection: $method, label: Text("by:")) {
                    Text("Element ID").tag(AddPartMethod.byElement)
                    Text("Part ID").tag(AddPartMethod.byMoldAndColor)
//                    Text("Set").tag(AddPartMethod.bySet)
                }.pickerStyle(SegmentedPickerStyle())
            }.padding(.bottom)
            
            HStack {
                TextField(placeholders[method]!, text: $input)
                Button(action: {
                    Task {
                        switch method {
                        case .byElement:
                            await manager.searchParts(byElementId: input)
                        case .byMoldAndColor:
                            await manager.searchParts(byPartId: input)
                        case .bySet:
                            print("TODO")
                        }
                    }
                }) {
                    Text("Search")
                }.disabled(input.isEmpty)
            }
            Spacer()
            if manager.searchedParts.loading {
                ProgressView()
            } else if manager.searchedParts.result != nil {
                PartSelectionView(parts: (manager.searchedParts.result)!)
            } else {
                Text(manager.searchedParts.error?.localizedDescription ?? "Enter Search")
            }
            Spacer()
            HStack {
                Button(action:{
                    isPresented = false
                }) {
                    Text("Cancel")
                }
                Spacer()
                Button(action:{
                    let elements = manager.searchedParts.result!
                    appManager.upsertParts(elements: elements)
                    isPresented = false
                }) {
                    Text("Add Part")
                }
                .disabled(manager.searchedParts.result == nil)
                .keyboardShortcut(.defaultAction)
            }
        }.padding()
    }
}

struct AddPartView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        AddPartView(isPresented: .constant(true))
            .environmentObject(manager as RebrickableManager)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
