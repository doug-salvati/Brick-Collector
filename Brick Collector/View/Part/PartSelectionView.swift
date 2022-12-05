//
//  PartSelectionView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/21/21.
//

import SwiftUI
import Combine

struct PartSelectionView: View {
    @Binding
    var selections:[ElementSelection]
    @State private var colorFilter:Int = -999
        
    func getFormatter() -> NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.minimum = 1
        numberFormatter.maximum = 10000
        return numberFormatter
    }
    
    var body: some View {
        let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
        let colorIds = Set(selections.map { $0.value.colorId })
        VStack {
            HStack {
                ColorPicker(availableColorIds: Array(colorIds), colorFilter: $colorFilter)
                Spacer()
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
                            VStack {
                                if selection.value.img != nil {
                                    AsyncImage(url: URL(string: selection.value.img!)!).padding()
                                } else {
                                    Image(systemName: "photo")
                                }
                                Toggle(isOn: $selection.selected) {
                                    Stepper(value: $selection.quantity, in: 1...10000) {
                                        TextField("", value: $selection.quantity, formatter: getFormatter())
                                    }.disabled(!selection.selected)
                                }.padding(.leading).padding(.trailing).padding(.bottom)
                            }.background(
                                RoundedRectangle(cornerRadius: 5).fill(Color("IconBorder")).opacity(0.2)
                            )
                        }
                    }
                }
            }
        }
    }
}

struct PartSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        PartSelectionView(selections: .constant([])).frame(width: 300)
    }
}
