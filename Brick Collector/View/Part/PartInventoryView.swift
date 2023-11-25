//
//  PartInventoryView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/29/21.
//

import SwiftUI

struct PartInventoryView: View {
    @EnvironmentObject private var appManager: AppManager
    var inventory:[InventoryItem]
    @AppStorage("setSort")
    private var setSort:SetSortOption = .id
    var style:InventoryViewChoice = .icons

    private func getSortMethod() -> (InventoryItem, InventoryItem) -> Bool {
        switch setSort {
        case .id:
            return {
                let firstBaseId = Int($0.kit!.id!.split(separator: "-").first ?? "0") ?? 0
                let secondBaseId = Int($1.kit!.id!.split(separator: "-").first ?? "0") ?? 0
                return firstBaseId < secondBaseId
            }
        case .name:
            return {$0.kit?.name ?? "" < $1.kit?.name ?? ""}
        case .theme:
            return {$0.kit?.theme ?? "" < $1.kit?.theme ?? ""}
        }
    }
    
    var body: some View {
        let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
        ScrollView {
            if style == .icons {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(inventory.sorted(by: getSortMethod())) { usage in
                        let set = usage.kit!
                        Button(action: {
                            appManager.activeTab = .sets
                            appManager.activeSetFeature = set
                        }) {
                            ZStack {
                                Rectangle().aspectRatio(1, contentMode: .fill).foregroundColor(.white)
                                if set.img?.binary != nil {
                                    Image(nsImage: NSImage(data: set.img!.binary!)!).resizable().scaledToFit().padding()
                                } else {
                                    Image(systemName: "photo").foregroundColor(.black)
                                }
                                VStack {
                                    Spacer()
                                    HStack {
                                        let setQuantity = usage.kit!.quantity
                                        let suffix = setQuantity > 1 ? " (\(setQuantity))" : ""
                                        Text("\(usage.quantity)x in \(set.id!)\(suffix)").fontWeight(.bold).colorInvert().padding()
                                        Spacer()
                                    }
                                }
                            }.clipped().aspectRatio(1, contentMode: .fit)
                        }.buttonStyle(.plain)
                    }
                }
            } else {
                LazyVStack  {
                    ForEach(inventory.sorted(by: getSortMethod())) { usage in
                        let set = usage.kit!
                        VStack {
                            Button(action: {
                                appManager.activeTab = .sets
                                appManager.activeSetFeature = set
                            }) {
                                HStack {
                                    Text("\(usage.quantity)x in").fontWeight(.bold).padding(.trailing)
                                    if set.img?.binary != nil {
                                        Image(nsImage: NSImage(data: set.img!.binary!)!).resizable().frame(width: 50, height: 50)
                                    } else {
                                        Image(systemName: "photo").resizable().frame(width: 50, height: 50).foregroundColor(.black).background(.white)
                                    }
                                    VStack(alignment: .leading) {
                                        Text(set.name ?? "Unknown Name")
                                        HStack {
                                            Image(systemName: "tag")
                                            Text(set.theme ?? "Unknown Theme")
                                        }
                                    }.padding(.leading)
                                    Spacer()
                                }
                            }.buttonStyle(.plain)
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

struct PartInventoryView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        PartInventoryView(inventory: []).environmentObject(AppManager(using: manager))
    }
}
