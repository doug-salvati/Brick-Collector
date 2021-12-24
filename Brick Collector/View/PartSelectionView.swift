//
//  PartSelectionView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/21/21.
//

import SwiftUI

struct PartSelectionView: View {
    var parts:[Element]
    @Binding
    var selections:[ElementSelection]
    @State private var colorFilter:Int = -999
    
    var body: some View {
        let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
        let colorIds = Set(selections.map { $0.value.colorId })
        VStack {
            Picker("Color:", selection: $colorFilter) {
                Text("All").tag(-999)
                ForEach(Array(colorIds).sorted(), id: \.self) { ColorNameView(type: .Label, colorId: $0).tag($0) }
            }
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach($selections) { $selection in
                        if (colorFilter == -999 || selection.value.colorId == colorFilter) {
                            Toggle(isOn: $selection.selected) {
                                AsyncImage(url: URL(string: selection.value.img)!)
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
        let element = Element(id: "4106356", img: "foo.png", name: "Brick 2x4", colorId: 0)
        PartSelectionView(parts: [element], selections: .constant([])).frame(width: 300)
    }
}
