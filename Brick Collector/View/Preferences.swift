//
//  Preferences.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/8/21.
//

import SwiftUI

struct Preferences: View {
    @AppStorage("apiKey")
    private var apiKey:String = ""
    
    @AppStorage("colorSet")
    private var colorSet:ColorSet = .bricklink
    
    @EnvironmentObject private var manager: RebrickableManager
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("Rebrickable API Key")
                    Link(destination: URL(string: "https://rebrickable.com/api/")!) {
                        Image(systemName: "questionmark")
                    }
                }
                SecureField("", text: $apiKey)
            }.padding()
            Form {
                HStack {
                    Picker("Color Names:", selection: $colorSet) {
                        ForEach(ColorSet.allCases) {
                            set in
                            Text(set.rawValue)
                        }
                    }.frame(width:200)
                    Button(action: {
                        ColorManager.updateColors(using: manager)
                    }) {
                        Text("Update Colors")
                    }
                }
            }
            .navigationTitle("Preferences")
        }
        .frame(width: 400, height: 300)
        .padding()
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        Preferences().environmentObject(manager as RebrickableManager)
    }
}
