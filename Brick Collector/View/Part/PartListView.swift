//
//  PartListView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/20/21.
//

import SwiftUI

struct PartListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appManager: AppManager
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Part.id, ascending: true)],
        animation: .default)
    private var parts: FetchedResults<Part>
    private var filteredParts: [Part] {
        parts.filter {
            (
                filter == nil ||
                filter == "" ||
                $0.name!.filterable().contains(filter!.filterable()) ||
                filter!.filterable() == "jang" && ["4261572", "4621635", "6035345"].contains($0.id!)
            ) && (
                colorFilter == -999 ||
                colorFilter == $0.colorId
            )
        }
    }
    var filter:String?
    @State private var colorFilter:Int = -999

    var body: some View {
        let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 4)
        let partCount = parts.reduce(0) { $0 + $1.quantity }
        let colorIds = Set(parts.map { Int($0.colorId) })
        
        VStack {
            if appManager.activePartFeature == nil {
                HStack {
                    Picker(selection: $colorFilter, content: {
                        Text("All").tag(-999)
                        Divider()
                        ForEach(Array(colorIds).sorted(), id: \.self) { ColorNameView(type: .Label, colorId: $0, stroke: .black).tag($0) }
                    }) {
                        Label("Color", systemImage: "paintpalette.fill").labelStyle(.iconOnly)
                    }.frame(width: 200).padding()
                    Spacer()
                    Text("\(partCount) Parts (\(parts.count) Unique)").font(.title2).padding()
                }
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(filteredParts) { part in
                            Button(action: {
                                withAnimation {
                                    appManager.activePartFeature = part
                                }
                            }) {
                                HStack {
                                    ZStack {
                                        Rectangle().aspectRatio(1, contentMode: .fill).foregroundColor(.white)
                                        if part.img != nil && NSImage(data: part.img!) != nil {
                                            Image(nsImage: NSImage(data: part.img!)!).resizable().scaledToFit().padding()
                                        } else {
                                            Image(systemName: "photo").foregroundColor(.black)
                                        }
                                        VStack {
                                            HStack {
                                                Spacer()
                                                ColorNameView(type: .Icon, colorId: Int(part.colorId), stroke: .black).scaleEffect(2).padding()
                                            }
                                            Spacer()
                                            HStack {
                                                Text("\(part.quantity)x").fontWeight(.bold).colorInvert().padding()
                                                Spacer()
                                            }
                                        }
                                    }.clipped().aspectRatio(1, contentMode: .fit)
                                }
                            }.buttonStyle(.plain)
                        }
                    }
                }
            } else {
                PartFeatureView(part: appManager.activePartFeature!).transition(AnyTransition.move(edge: .trailing))
            }
        }.onAppear {
            appManager.activeSetFeature = nil
        }
    }

}

struct PartListView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        PartListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext).environmentObject(AppManager(using: manager))
    }
}
