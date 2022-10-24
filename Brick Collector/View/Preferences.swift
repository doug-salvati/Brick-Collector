//
//  Preferences.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/8/21.
//

import SwiftUI

enum PreferenceView:String {
    case general = "General"
    case colors = "Colors"
    case parts = "Parts"
    case sets = "Sets"
}

enum SetSuffixOption: String {
    case never = "never"
    case always = "always"
    case notOne = "notOne"
}

struct Preferences: View {
    @AppStorage("apiKey")
    private var apiKey:String = ""
    
    @AppStorage("colorSet")
    private var colorSet:ColorSet = .bricklink
    
    @AppStorage("separateBasicColors")
    private var separateBasicColors:Bool = true
    
    @AppStorage("separateTransColors")
    private var separateTransColors:Bool = true
    
    @AppStorage("colorsLastUpdated")
    private var colorsLastUpated:Int = 0
    
    @AppStorage("defaultAddPartMethod")
    private var defaultAddPartMethod:AddPartMethod = .byElement
    
    @AppStorage("setSuffixOption")
    private var setSuffixOption:SetSuffixOption = .notOne
    
    @AppStorage("jumpToNewSet")
    private var jumpToNewSet:Bool = true
    
    @AppStorage("homepage")
    private var homepage:AppView = .parts
    
    @EnvironmentObject private var appManager: AppManager
    
    var body: some View {
        let loadingColors:Bool = appManager.isLoading(type: .UpdateColors)
        TabView {
            VStack {
                VStack {
                    HStack {
                        Text("Rebrickable API Key")
                        Link(destination: URL(string: "https://rebrickable.com/api/")!) {
                            Image(systemName: "questionmark")
                        }
                    }
                    SecureField("", text: $apiKey).frame(width: 400)
                }.padding(.bottom)
                Form {
                    Picker("Home Page:", selection: $homepage) {
                        Text("Parts").tag(AppView.parts)
                        Text("Sets").tag(AppView.sets)
                    }.frame(width:250)
                }
            }
            .padding()
            .tabItem {
                Label("General", systemImage: "gearshape")
            }.frame(width: 600, height: 150)
            VStack {
                Form {
                    Picker("Color Names:", selection: $colorSet) {
                        ForEach(ColorSet.allCases) {
                            set in
                            Text(set.rawValue)
                        }
                    }.frame(width:200)
                    Toggle(isOn: $separateBasicColors) {
                        Text("Separate basic colors in dropdowns")
                    }
                    Toggle(isOn: $separateTransColors) {
                        Text("Separate translucent colors in dropdowns")
                    }
                }
                Spacer()
                VStack {
                    if loadingColors {
                        ProgressView().scaleEffect(2/3)
                    }
                    Button(action: {
                        Task {
                            await appManager.updateColors()
                        }
                    }) {
                        Text("Update Colors")
                    }.disabled(loadingColors)
                    Text("Brick Collector automatically checks for color updates weekly.")
                        .font(.footnote)
                    Text("Last updated \(Date(timeIntervalSince1970: TimeInterval(colorsLastUpated)).formatted())")
                        .font(.footnote)
                }
            }.tabItem {
                Label("Colors", systemImage: "paintpalette")
            }.frame(width: 600, height: 175).padding()
            Form {
                Picker("Default Part Addition:", selection: $defaultAddPartMethod) {
                    Text("by Element ID").tag(AddPartMethod.byElement)
                    Text("by Part ID").tag(AddPartMethod.byMoldAndColor)
                    Text("by Set").tag(AddPartMethod.bySet)
                }.frame(width:250)
            }.tabItem {
                Label("Parts", systemImage: "puzzlepiece")
            }.frame(width: 600, height: 100)
            Form {
                Picker("Display Set Suffixes:", selection: $setSuffixOption) {
                    Text("always").tag(SetSuffixOption.always)
                    Text("never").tag(SetSuffixOption.never)
                    Text("when not 1").tag(SetSuffixOption.notOne)
                }.frame(width:250)
                Toggle(isOn: $jumpToNewSet) {
                    Text("Jump to new set after adding")
                }
            }.tabItem {
                Label("Sets", systemImage: "shippingbox")
            }.frame(width: 600, height: 100)
        }.frame(width: 600)
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        Preferences().environmentObject(AppManager(using: manager))
    }
}
