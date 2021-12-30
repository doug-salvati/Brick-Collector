//
//  SetListView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/20/21.
//

import SwiftUI

struct SetListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appManager: AppManager

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Kit.id, ascending: true)],
        animation: .default)
    private var sets: FetchedResults<Kit>

    var body: some View {
        let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 4)
        let setCount = sets.reduce(0) { $0 + $1.quantity }
        VStack {
            if appManager.activeSetFeature == nil {
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(sets) { set in
                            Button(action: {
                                withAnimation {
                                    appManager.activeSetFeature = set
                                }
                            }) {
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
                                                SetIdView(setId: set.id!, fontWeight: .bold).colorInvert()
                                                Text(set.quantity > 1 ? "(\(set.quantity))" : "").fontWeight(.bold).colorInvert()
                                                Spacer()
                                            }.padding()
                                        }
                                    }
                                }
                            }.buttonStyle(.plain)
                        }
                    }
                    Text("\(setCount) Sets").font(.footnote).padding()
                }
            } else {
                SetFeatureView(set: appManager.activeSetFeature!).transition(AnyTransition.move(edge: .trailing))
            }
        }.onAppear {
            appManager.activePartFeature = nil
        }
    }

}

struct SetListView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        SetListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext).environmentObject(AppManager(using: manager))
    }
}
