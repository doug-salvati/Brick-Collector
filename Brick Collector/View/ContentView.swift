//
//  ContentView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/3/21.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appManager: AppManager

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Part.id, ascending: true)],
        animation: .default)
    private var parts: FetchedResults<Part>
    
    @State private var showModal = false
    
    var body: some View {
        VStack {
            List {
                ForEach(parts) { part in
                    HStack {
                        Text("\(part.quantity)x \(part.id!) \(part.name!)")
                        ColorNameView(colorId: Int(part.colorId))
                    }
                }
                .onDelete(perform: deleteParts)
            }
            .toolbar {
                if appManager.isLoading() {
                    Button(action: {}) {
                        ProgressView().scaleEffect(2/3)
                    }
                }
                Button(action: {
                    showModal = true
                }) {
                    Label("Add Part", systemImage: "plus")
                }
            }
        }.sheet(isPresented: $showModal) {
            AddPartView(isPresented: $showModal)
                .frame(width: 300, height: 300, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
        }.frame(width: 800, height: 500, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }

    private func deleteParts(offsets: IndexSet) {
        withAnimation {
            offsets.map { parts[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext).environmentObject(AppManager(using: manager))
    }
}
