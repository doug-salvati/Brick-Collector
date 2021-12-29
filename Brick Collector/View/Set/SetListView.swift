//
//  SetListView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/20/21.
//

import SwiftUI

struct SetListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Kit.id, ascending: true)],
        animation: .default)
    private var sets: FetchedResults<Kit>

    var body: some View {
        List {
            ForEach(sets) { set in
                HStack {
                    if set.img != nil {
                        Image(nsImage: NSImage(data: set.img!)!).resizable().frame(height: 100).aspectRatio(1, contentMode: .fit)
                    } else {
                        Image(systemName: "photo")
                    }
                    Text("\(set.quantity)x \(set.theme!) \(set.id!) \(set.name!)")
                }
            }
        }
    }

}

struct SetListView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        SetListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext).environmentObject(AppManager(using: manager))
    }
}
