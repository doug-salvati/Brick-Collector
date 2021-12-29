//
//  SetIdView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/29/21.
//

import SwiftUI

struct SetIdView: View {
    var setId:String
    var fontWeight:Font.Weight = .regular
    @AppStorage("showSetSuffix") private var showSuffix:Bool = false
    
    var body: some View {
        let displayId = showSuffix ? setId : String(setId.split(separator: "-").first ?? Substring(setId))
        Text(displayId).fontWeight(fontWeight)
    }
}

struct SetIdView_Previews: PreviewProvider {
    static var previews: some View {
        SetIdView(setId: "1234-1")
    }
}
