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
    var quantity: Int = 1
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
    @State private var method:AddPartMethod = AddPartMethod(rawValue: UserDefaults.standard.string(forKey: "defaultAddPartMethod") ?? "byElement") ?? .byElement
    @State
    var selections:[ElementSelection] = []
    private var setSearch:String {
        "\(input)\(suffix)"
    }
    
    func getSelectionCount() -> Int {
        return selections.filter{$0.selected}.reduce(0) {$0 + $1.quantity}
    }
    
    func search() async {
        switch method {
        case .byElement:
            await manager.searchParts(byElementId: input)
        case .byMoldAndColor:
            await manager.searchParts(byPartId: input)
        case .bySet:
            await manager.searchInventory(bySetId: setSearch)
        }
    }
    
    var body: some View {
        let loading = manager.searchedParts.loading || manager.searchedInventory.loading
        let error = manager.searchedParts.error ?? manager.searchedInventory.error
        let resultsPresent = method == .bySet ? manager.searchedInventory.result != nil : manager.searchedParts.result != nil
        VStack {
            VStack {
                HStack {
                    Text("Add Parts")
                        .font(.largeTitle)
                    Spacer()
                }
                if !appManager.importing {
                    Picker(selection: $method, label: Text("by:")) {
                        Text("Element ID").tag(AddPartMethod.byElement)
                        Text("Part ID").tag(AddPartMethod.byMoldAndColor)
                        Text("Set").tag(AddPartMethod.bySet)
                    }.pickerStyle(SegmentedPickerStyle()).onChange(of: method) { method in
                        manager.resetParts()
                        manager.resetInventory()
                    }
                }
            }.padding(.bottom)

            if !appManager.importing {
                HStack {
                    TextField(placeholders[method]!, text: $input).onSubmit {
                        Task {
                            await search()
                        }
                    }
                    if method == .bySet {
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
            }
            Spacer()
            if loading {
                VStack {
                    ProgressView().padding()
                    if appManager.importing {
                        Text("Fetching data at reduced speed. Please be patient.").font(.footnote).italic().multilineTextAlignment(.center)
                    }
                }
            } else if resultsPresent {
                PartSelectionView(selections: $selections)
            } else {
                Text(error?.localizedDescription ?? "Enter Search")
            }
            Spacer()
            HStack {
                Button(action:{
                    manager.resetParts()
                    isPresented = false
                    appManager.importing = false
                }) {
                    Text("Cancel")
                }.disabled(appManager.importing && loading)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(action:{
                    appManager.upsertParts(selections: selections.filter{$0.selected})
                    manager.resetParts()
                    manager.resetInventory()
                    isPresented = false
                    appManager.importing = false
                }) {
                    let partCount = getSelectionCount()
                    switch getSelectionCount() {
                    case 0, 1:
                        Text("Add Part")
                    default:
                        Text("Add \(partCount) Parts")
                    }
                }
                .disabled(!resultsPresent || getSelectionCount() < 1)
                .keyboardShortcut(.defaultAction)
            }
        }.padding().onReceive(manager.$searchedParts) { newParts in
            self.selections = (newParts.result ?? []).map { part in
                return ElementSelection(value: part, selected: appManager.importing || method != .byMoldAndColor, quantity: 1)
            }
        }.onReceive(manager.$searchedInventory) { newInventory in
            self.selections = consolidate(inventory: newInventory.result ?? []).map { item in
                let element = RBElement(id: item.id, img: item.part.img ?? nil, name: item.part.name, colorId: item.color.id)
                return ElementSelection(value: element, selected: appManager.importing || method != .byMoldAndColor, quantity: item.quantity)
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
