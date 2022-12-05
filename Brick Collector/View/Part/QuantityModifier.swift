//
//  QuantityModifier.swift
//  Brick Collector
//
//  Created by Doug Salvati on 11/14/22.
//

import SwiftUI

func getFormatter() -> NumberFormatter {
    let numberFormatter = NumberFormatter()
    numberFormatter.minimum = 0
    numberFormatter.maximum = 10000
    return numberFormatter
}
let formatter = getFormatter()

struct QuantityModifier: View {
    @Binding var value:Int
    @State private var count = 0
    
    var body: some View {
        VStack {
            Text("Bulk Add").font(.title)
            Stepper(value: $count, in: 0...10000) {
                TextField("", value: $count, formatter: getFormatter()).frame(width: 100)
            }
            Button("Add \(String(count))") {
                value += count
            }.disabled(count < 1).keyboardShortcut(.defaultAction)
        }
    }
}

struct QuantityModifier_Previews: PreviewProvider {
    static var previews: some View {
        QuantityModifier(value: .constant(99))
    }
}
