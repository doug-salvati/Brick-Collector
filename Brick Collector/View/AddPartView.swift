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
    @State private var input:String = ""
    
    var body: some View {
        VStack {
            HStack {
                TextField("Element ID", text: $input)
                Button(action: {
                    manager.searchPart(byElementId: input)
                }) {
                    Text("Search")
                }
            }
            Spacer()
            if manager.searchedPart?.result != nil {
                AddPartPreview(element: (manager.searchedPart?.result)!)
            } else {
                Text(manager.searchedPart?.error?.localizedDescription ?? "Enter Search")
            }
            Spacer()
            HStack {
                Button(action:{
                    isPresented = false
                }) {
                    Text("Cancel")
                }
                Spacer()
                Button(action:{}) {
                    Text("Add Part")
                }.disabled(true)
//                .disabled(manager.searchedPart?.result == nil)
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
    }
}
