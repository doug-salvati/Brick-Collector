//
//  AddPartView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/3/21.
//

import SwiftUI

struct AddPartView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var manager: RebrickableManager
    @Environment(\.managedObjectContext) private var viewContext
    @State private var input:String = ""
    
    var body: some View {
        VStack {
            HStack {
                TextField("Element ID", text: $input)
                Button(action: {
                    manager.searchPart(byElementId: input)
                }) {
                    Text("Search")
                }.disabled(input.isEmpty)
            }
            Spacer()
            if manager.searchedPart.loading {
                ProgressView()
            } else if manager.searchedPart.result != nil {
                AddPartPreview(element: (manager.searchedPart.result)!)
            } else {
                Text(manager.searchedPart.error?.localizedDescription ?? "Enter Search")
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
                    let element = manager.searchedPart.result!
                    let newPart = Part(context: viewContext)
                    newPart.id = element.id
                    newPart.name = element.name
                    newPart.colorId = Int64(element.colorId)
                    newPart.quantity = 1
                    newPart.loose = 1
                    newPart.img = ""
                    DispatchQueue.main.async {
                        try! viewContext.save()
                    }
                    isPresented = false
                }) {
                    Text("Add Part")
                }
                .disabled(manager.searchedPart.result == nil)
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
