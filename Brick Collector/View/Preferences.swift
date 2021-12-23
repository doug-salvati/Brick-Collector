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
    
    @AppStorage("defaultAddPartMethod")
    private var defaultAddPartMethod:AddPartMethod = .byElement
    
    @EnvironmentObject private var appManager: AppManager
    
    var body: some View {
        let loadingColors:Bool = appManager.isLoading(type: .UpdateColors)
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
                        Task {
                            await appManager.updateColors()
                        }
                    }) {
                        Text("Update Colors")
                    }.disabled(loadingColors)
                    if loadingColors {
                        ProgressView().scaleEffect(2/3)
                    } else {
                        ProgressView().scaleEffect(2/3).hidden()
                    }
                }
                HStack {
                    Picker("Default Part Addition:", selection: $defaultAddPartMethod) {
                        Text("by Element ID").tag(AddPartMethod.byElement)
                        Text("by Part ID").tag(AddPartMethod.byMoldAndColor)
                    }.frame(width:250)
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
        Preferences().environmentObject(AppManager(using: manager))
    }
}
