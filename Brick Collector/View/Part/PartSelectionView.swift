//
//  PartSelectionView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/21/21.
//

import SwiftUI

struct PartSelectionView: View {
    var parts:[RBElement]
    @Binding
    var selections:[ElementSelection]
    @State private var colorFilter:Int = -999
    
    var body: some View {
        let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
        let colorIds = Set(selections.map { $0.value.colorId })
        VStack {
            Picker("Color:", selection: $colorFilter) {
                Text("All").tag(-999)
                Divider()
                ForEach(Array(colorIds).sorted(), id: \.self) { ColorNameView(type: .Label, colorId: $0, stroke: .black).tag($0) }
            }
            HStack {
                Button(action: {
                    $selections.forEach { $selection in
                        if (!selection.selected) {
                            selection.selected.toggle()
                        }
                    }
                }, label: { Text("Select All") })
                Button(action: {
                    $selections.forEach { $selection in
                        if (selection.selected) {
                            selection.selected.toggle()
                        }
                    }
                }, label: { Text("Deselect All") })
                Spacer()
            }
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach($selections) { $selection in
                        if (colorFilter == -999 || selection.value.colorId == colorFilter) {
                            Toggle(isOn: $selection.selected) {
                                if selection.value.img != nil {
                                    AsyncImage(url: URL(string: selection.value.img!)!)
                                } else {
                                    Image(systemName: "photo")
                                }
                            }.toggleStyle(.gallery)
                        }
                    }
                }
            }
        }
    }
}

struct PartSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let element = RBElement(id: "4106356", img: "foo.png", name: "Brick 2x4", colorId: 0)
        PartSelectionView(parts: [element], selections: .constant([])).frame(width: 300)
    }
}
