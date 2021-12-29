//
//  ColorNameView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/10/21.
//

import SwiftUI

enum ColorViewType {
    case Icon
    case Label
    case IconAndLabel
}

struct ColorNameView: View {
    var type:ColorViewType = .IconAndLabel
    var colorId:Int
    var color:PartColor? {
        colors.first(where: {$0.id == colorId})
    }
    
    @AppStorage("colorSet") private var colorSet:ColorSet = .bricklink

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PartColor.id, ascending: true)],
        animation: .default)
    private var colors: FetchedResults<PartColor>
    
    private func colorDisplayName(id:Int) -> String {
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
        Group {
            switch(type) {
            case .Icon:
                icon
            case .Label:
                label
            case .IconAndLabel:
                HStack {
                    icon
                    label
                }
            }
        }
    }
    
    var icon: some View {
        Circle()
            .foregroundColor(Color(hex: color?.hex ?? "000000"))
            .fixedSize()
            .overlay(Circle().stroke(.black), alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
    var label: some View {
        Text(colorDisplayName(id: colorId))
    }
}

struct ColorNameView_Previews: PreviewProvider {
    static var previews: some View {
        ColorNameView(colorId: 1).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
