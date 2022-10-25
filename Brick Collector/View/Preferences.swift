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

enum PartSortOption: String {
    case color = "color"
    case name = "name"
    case quantityDown = "quantity (high to low)"
    case quantityUp = "quantity (low to high)"
}

enum SetSortOption: String {
    case id = "id"
    case name = "name"
    case theme = "theme"
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
    
    @AppStorage("partSort")
    private var partSort:PartSortOption = .color
    
    @AppStorage("defaultAddPartMethod")
    private var defaultAddPartMethod:AddPartMethod = .byElement
    
    @AppStorage("setSort")
    private var setSort:SetSortOption = .id
    
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
                    Picker("Home page:", selection: $homepage) {
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
                    Picker("Color names:", selection: $colorSet) {
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
                Picker("Sort collection by:", selection: $partSort) {
                    Text("color").tag(PartSortOption.color)
                    Text("name").tag(PartSortOption.name)
                    Text("quantity (high to low)").tag(PartSortOption.quantityDown)
                    Text("quantity (low to high)").tag(PartSortOption.quantityUp)
                }.frame(width:300)
                Picker("Default part addition:", selection: $defaultAddPartMethod) {
                    Text("by element ID").tag(AddPartMethod.byElement)
                    Text("by part ID").tag(AddPartMethod.byMoldAndColor)
                    Text("by set").tag(AddPartMethod.bySet)
                }.frame(width:250)
            }.tabItem {
                Label("Parts", systemImage: "puzzlepiece")
            }.frame(width: 600, height: 100)
            Form {
                Picker("Sort collection by:", selection: $setSort) {
                    Text("ID").tag(SetSortOption.id)
                    Text("name").tag(SetSortOption.name)
                    Text("theme").tag(SetSortOption.theme)
                }.frame(width:250)
                Picker("Display set suffixes:", selection: $setSuffixOption) {
                    Text("always").tag(SetSuffixOption.always)
                    Text("never").tag(SetSuffixOption.never)
                    Text("when not 1").tag(SetSuffixOption.notOne)
                }.frame(width:250)
                Toggle(isOn: $jumpToNewSet) {
                    Text("Jump to new set after adding")
                }
            }.tabItem {
                Label("Sets", systemImage: "shippingbox")
            }.frame(width: 600, height: 125)
        }.frame(width: 600)
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        Preferences().environmentObject(AppManager(using: manager))
    }
}
