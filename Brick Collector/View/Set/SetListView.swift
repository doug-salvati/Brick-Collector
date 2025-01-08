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
    private var filteredSets: [Kit] {
        sets.filter {
            (
                filter == nil ||
                filter == "" ||
                $0.name!.filterable().contains(filter!.filterable())
            ) && (
                themeFilter == "All" ||
                themeFilter == $0.theme!
            )
        }
    }
    var filter:String?
    @State private var themeFilter:String = "All"
    @AppStorage("setSort")
    private var setSort:SetSortOption = .id
    @AppStorage("zoomLevel")
    private var zoomLevel:Int = 4

    private func getSortMethod() -> (Kit, Kit) -> Bool {
        switch setSort {
        case .id:
            return {
                let firstBaseId = Int($0.id!.split(separator: "-").first ?? "0") ?? 0
                let secondBaseId = Int($1.id!.split(separator: "-").first ?? "0") ?? 0
                return firstBaseId < secondBaseId
            }
        case .name:
            return {$0.name ?? "" < $1.name ?? ""}
        case .theme:
            return {$0.theme ?? "" < $1.theme ?? ""}
        }
    }

    var body: some View {
        let columns: [GridItem] = Array(repeating: .init(.flexible()), count: zoomLevel)
        let setCount = sets.reduce(0) { $0 + $1.quantity }
        let themeNames = Set(sets.map { $0.theme! })
        VStack {
            if appManager.activeSetFeature == nil {
                HStack {
                    Picker(selection: $themeFilter, content: {
                        Text("All").tag("All")
                        Divider()
                        ForEach(Array(themeNames).sorted(), id: \.self) {
                            Text($0).tag($0)
                        }
                    }) {
                        Label("Theme", systemImage: "tag").labelStyle(.iconOnly)
                    }.frame(width: 200).padding()
                    Spacer()
                    Text("\(setCount) Sets").font(.title2).padding()
                }
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(filteredSets.sorted(by: getSortMethod())) { set in
                            Button(action: {
                                withAnimation {
                                    appManager.activeSetFeature = set
                                }
                            }) {
                                HStack {
                                    ZStack {
                                        Rectangle().aspectRatio(1, contentMode: .fill).foregroundColor(.white)
                                        if set.img?.binary != nil {
                                            Image(nsImage: NSImage(data: set.img!.binary!)!).resizable().scaledToFit().padding()
                                        } else {
                                            Image(systemName: "photo").foregroundColor(.black)
                                        }
                                        VStack {
                                            HStack {
                                                Spacer()
                                                if (set.missingFigs) {
                                                    Label("Set is missing minifigures.", systemImage: "person.crop.circle.badge.xmark").labelStyle(.iconOnly).imageScale(.large).colorInvert().padding()
                                                }
                                            }
                                            Spacer()
                                            HStack {
                                                SetIdView(setId: set.id!, fontWeight: .bold).colorInvert()
                                                Text(set.quantity > 1 ? "(\(set.quantity))" : "").fontWeight(.bold).colorInvert()
                                                Spacer()
                                            }.padding()
                                        }
                                    }.clipped().aspectRatio(1, contentMode: .fit)
                                }
                            }.buttonStyle(.plain)
                        }
                    }
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
