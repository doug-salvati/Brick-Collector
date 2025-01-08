//
//  ColorPicker.swift
//  Brick Collector
//
//  Created by Doug Salvati on 10/23/22.
//

import SwiftUI

let basicColors:[String] = [
    "Black",
    "Blue",
    "Dark Bluish Gray",
    "Green",
    "Light Bluish Gray",
    "Orange",
    "Red",
    "Reddish Brown",
    "White",
    "Yellow",
]

struct ColorPicker: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PartColor.id, ascending: true)],
        animation: .default)
    private var colors: FetchedResults<PartColor>
    var availableColorIds:[Int] = []
    var showEveryColor = false
    var showAll = true
    var label:Text?
    @Binding
    var colorFilter:Int
    var availableColors:[PartColor] {
        if showEveryColor {
            return colors.map { $0 }
        }
        return availableColorIds.filter { colorId in
            return colors.contains(where: {$0.id == colorId})
        }.map { colorId in
            return colors.first(where: {$0.id == colorId})!
        }
    }
    @AppStorage("colorSet") private var colorSet:ColorSet = .bricklink
    @AppStorage("separateBasicColors") private var separateBasicColors:Bool = true
    @AppStorage("separateTransColors") private var separateTransColors:Bool = true
    
    private func sortedColors() -> [PartColor] {
        switch(colorSet) {
        case .bricklink:
            return availableColors.sorted(by: {$0.bricklinkName ?? "" < $1.bricklinkName ?? ""})
        case .rebrickable:
            return availableColors.sorted(by: {$0.rebrickableName ?? "" < $1.rebrickableName ?? ""})
        default:
            return availableColors.sorted(by: {$0.name ?? "" < $1.name ?? ""})
        }
    }
    
    private func getSections() -> [[PartColor]] {
        var basicSection:[PartColor] = [];
        var transSection:[PartColor] = [];
        var otherSection:[PartColor] = [];
        sortedColors().forEach { color in
            if separateBasicColors && basicColors.contains(color.bricklinkName ?? "continue") {
                basicSection.append(color)
            } else if separateTransColors && (color.bricklinkName ?? "continue").contains("Trans-") {
                transSection.append(color)
            } else {
                otherSection.append(color)
            }
        }
        return [
            basicSection,
            otherSection,
            transSection
        ]
    }
    
    var body: some View {
        Picker(selection: $colorFilter, content: {
            if showAll { Text("All").tag(-999) }
            ForEach(getSections(), id: \.self) {
                Divider()
                ForEach($0) {
                    ColorNameView(type: .Label, colorId: Int($0.id), stroke: .black).tag(Int($0.id))
                }
            }
        }) {
            if ((label) != nil) {
                label
            } else {
                Label("Color", systemImage: "paintpalette.fill").labelStyle(.iconOnly)
            }
        }.frame(width: 200)
    }
}

struct ColorPicker_Previews: PreviewProvider {
    static var previews: some View {
        ColorPicker(availableColorIds: [], colorFilter: .constant(-999))
    }
}
