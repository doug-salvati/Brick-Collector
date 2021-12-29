//
//  PartListView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/20/21.
//

import SwiftUI

struct PartListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Part.id, ascending: true)],
        animation: .default)
    private var parts: FetchedResults<Part>

    var body: some View {
        let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 4)
        let partCount = parts.reduce(0) { $0 + $1.quantity }
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(parts) { part in
                    HStack {
                        ZStack {
                            Rectangle().aspectRatio(1, contentMode: .fill).foregroundColor(.white)
                            if part.img != nil {
                                Image(nsImage: NSImage(data: part.img!)!).resizable().scaledToFit().padding()
                            } else {
                                Image(systemName: "photo").foregroundColor(.black)
                            }
                            VStack {
                                HStack {
                                    Spacer()
                                    ColorNameView(type: .Icon, colorId: Int(part.colorId)).scaleEffect(2).padding()
                                }
                                Spacer()
                                HStack {
                                    Text("\(part.quantity)x").fontWeight(.bold).colorInvert().padding()
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            Text("\(partCount) Parts (\(parts.count) Unique)").font(.footnote).padding()
        }
    }

}

struct PartListView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        PartListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext).environmentObject(AppManager(using: manager))
    }
}
