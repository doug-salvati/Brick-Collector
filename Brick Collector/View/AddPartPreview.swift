//
//  AddPartPreview.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/7/21.
//

import SwiftUI

struct AddPartPreview: View {
    var element:Element
    var body: some View {
        Text(element.name)
    }
}

struct AddPartPreview_Previews: PreviewProvider {
    static var previews: some View {
        let element = Element(id: "4106356", img: "foo.png", name: "Brick 2x4")
        return AddPartPreview(element: element)
    }
}