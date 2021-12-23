//
//  GalleryToggleStyle.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/22/21.
//

import Foundation
import SwiftUI

struct GalleryToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
            ZStack {
                Rectangle().aspectRatio(1, contentMode: .fill)
                configuration.label
                VStack {
                    Spacer()
                    HStack {
                        Button(action: { configuration.isOn.toggle() }) {
                            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle").foregroundColor(.blue).scaleEffect(2).padding()
                        }.buttonStyle(.plain)
                        Spacer()
                    }
                }
            }
    }
}

extension ToggleStyle where Self == GalleryToggleStyle {
    static var gallery: GalleryToggleStyle { .init() }
}

