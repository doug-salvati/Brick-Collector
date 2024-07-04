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
    @AppStorage("setSuffixOption") private var suffixOption:SetSuffixOption = .notOne
    
    var body: some View {
        let showSuffix = (suffixOption == .always) || (suffixOption == .notOne && String(setId.split(separator: "-").last ?? Substring(setId)) != "1")
        let displayId = showSuffix ? setId : String(setId.split(separator: "-").first ?? Substring(setId))
        Text(displayId).fontWeight(fontWeight).textSelection(.enabled)
    }
}

struct SetIdView_Previews: PreviewProvider {
    static var previews: some View {
        SetIdView(setId: "1234-1")
    }
}
