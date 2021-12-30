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

struct ElementSelection: Identifiable {
    var value: RBElement
    var id: String { value.id }
    var selected: Bool
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
    @State private var suffix:String = "-1"
    @State private var method:AddPartMethod = AddPartMethod(rawValue: UserDefaults.standard.string(forKey: "defaultAddPartMethod")!) ?? .byElement
    @State
    var selections:[ElementSelection] = []
    private var setSearch:String {
        "\(input)\(suffix)"
    }

    func getSelections() -> [RBElement] {
        return selections.filter { element in
            element.selected
        }.map { element in
            element.value
        }
    }
    
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
                    Text("Set").tag(AddPartMethod.bySet)
                }.pickerStyle(SegmentedPickerStyle()).onChange(of: method) { method in
                    manager.resetParts()
                }
            }.padding(.bottom)
            
            HStack {
                TextField(placeholders[method]!, text: $input)
                if method == .bySet {
                    Picker("Suffix", selection: $suffix) {
                        Text("No Suffix").tag("")
                        ForEach(1..<31) { Text("-\($0)").tag("-\($0)") }
                    }.labelsHidden()
                }
                Button(action: {
                    Task {
                        switch method {
                        case .byElement:
                            await manager.searchParts(byElementId: input)
                        case .byMoldAndColor:
                            await manager.searchParts(byPartId: input)
                        case .bySet:
                            await manager.searchParts(bySetId: setSearch)
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
                PartSelectionView(parts: (manager.searchedParts.result)!, selections: $selections)
            } else {
                Text(manager.searchedParts.error?.localizedDescription ?? "Enter Search")
            }
            Spacer()
            HStack {
                Button(action:{
                    manager.resetParts()
                    isPresented = false
                }) {
                    Text("Cancel")
                }
                Spacer()
                Button(action:{
                    appManager.upsertParts(elements: getSelections())
                    manager.resetParts()
                    isPresented = false
                }) {
                    let partCount = getSelections().count
                    switch partCount {
                    case 0, 1:
                        Text("Add Part")
                    default:
                        Text("Add \(partCount) Parts")
                    }
                }
                .disabled(manager.searchedParts.result == nil || getSelections().count < 1)
                .keyboardShortcut(.defaultAction)
            }
        }.padding().onReceive(manager.$searchedParts) { newParts in
            self.selections = (newParts.result ?? []).map { part in
                return ElementSelection(value: part, selected: method != .byMoldAndColor)
            }
        }
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