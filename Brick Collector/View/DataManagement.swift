//
//  DataManagement.swift
//  Brick Collector
//
//  Created by Doug Salvati on 11/9/23.
//

import SwiftUI

struct DataManagement: View {
    @Binding var isPresented: Bool
    var deleteCollection:()->Void
    @State private var confirmation = ""
    
    var body: some View {
        VStack {
            Text("Delete Collection").bold().font(.system(.title2)).foregroundStyle(.red)
            Divider()
            HStack {
                Image(systemName: "exclamationmark.octagon").font(.system(size: 30)).foregroundStyle(.red)
                VStack {
                    Text("Clears all part and set data. This cannot be undone.")
                    Text("Type 'Delete all my data' to confirm you are sure.")
                }
            }.padding()
            TextField("Delete all my data", text: $confirmation).frame(width: 200)
            HStack {
                Button(role: .cancel, action : {
                    isPresented = false
                }) {
                    Text("Cancel")
                }
                Spacer()
                Button(role: .destructive, action: {
                    isPresented = false
                    deleteCollection()
                }) {
                    Text("Delete Data")
                }.disabled(confirmation != "Delete all my data")
            }
        }
    }
}

#Preview {
    DataManagement(isPresented: .constant(true), deleteCollection: {
        print("delete collection")
    }).padding()
}
