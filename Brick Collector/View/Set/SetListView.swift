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
        let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 4)
        let setCount = sets.reduce(0) { $0 + $1.quantity }
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(sets) { set in
                    HStack {
                        ZStack {
                            Rectangle().aspectRatio(1, contentMode: .fill).foregroundColor(.white)
                            if set.img != nil {
                                Image(nsImage: NSImage(data: set.img!)!).resizable().scaledToFit().padding()
                            } else {
                                Image(systemName: "photo").foregroundColor(.black)
                            }
                            VStack {
                                Spacer()
                                HStack {
                                    Text(set.id!).fontWeight(.bold).colorInvert().padding()
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            Text("\(setCount) Sets").font(.footnote).padding()
        }
    }

}

struct SetListView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        SetListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext).environmentObject(AppManager(using: manager))
    }
}
