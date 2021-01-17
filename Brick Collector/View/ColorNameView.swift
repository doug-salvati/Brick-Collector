//
//  ColorNameView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/10/21.
//

import SwiftUI

struct ColorNameView: View {
    var colorId:Int
    
    @AppStorage("colorSet") private var colorSet:ColorSet = .bricklink

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PartColor.id, ascending: true)],
        animation: .default)
    private var colors: FetchedResults<PartColor>
    
    func colorDisplayName(id:Int) -> String {
        let color = colors.first(where: {$0.id == id})
        let defaultName:String = color?.name ?? color?.bricklinkName ?? color?.rebrickableName ?? "Unknown"
        switch(colorSet) {
        case .bricklink:
            return color?.bricklinkName ?? defaultName
        case .rebrickable:
            return color?.rebrickableName ?? defaultName
        default:
            return defaultName
        }
    }
    
    var body: some View {
        Text(colorDisplayName(id: colorId))
    }
}

struct ColorNameView_Previews: PreviewProvider {
    static var previews: some View {
        ColorNameView(colorId: 1).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
