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
    
    var body: some View {
        let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach($selections) { $selection in
                    Toggle(isOn: $selection.selected) {
                        AsyncImage(url: URL(string: selection.value.img)!)
                    }.toggleStyle(.gallery)
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
