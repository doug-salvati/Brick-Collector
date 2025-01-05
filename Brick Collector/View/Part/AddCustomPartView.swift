//
//  AddPartView.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/3/21.
//

import SwiftUI

struct AddCustomPartView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var appManager: AppManager
    @State private var name:String = ""
    @State private var color:Int = 0
    @State private var imagePath:String = ""
    @State private var showImport = false

    func submit() {
        let element = RBElement(id: "CUSTOM-" + UUID().uuidString, img: imagePath, name: name, colorId: color)
        let selection = ElementSelection(value: element, selected: true, quantity: 1)
        appManager.upsertParts(selections: [selection])
    }
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("Add Custom Part")
                        .font(.largeTitle)
                    Spacer()
                }
            }.padding(.bottom)
            Form {
                TextField(text: $name, prompt: Text("Brick 2x4")){
                    Text("Name:")
                }
                ColorPicker(showEveryColor: true, showAll: false, label: Text("Color:"), colorFilter: $color)
                HStack {
                    LabeledContent("Image:") {
                        Button("Choose Image...") {
                            showImport = true
                        }.fileImporter(isPresented: $showImport, allowedContentTypes: [.image]) { result in
                            do {
                                let selectedFile: URL = try result.get()
                                if (selectedFile.startAccessingSecurityScopedResource()) {
                                    imagePath = selectedFile.absoluteString
                                } else {
                                    imagePath = ""
                                }
                            } catch {
                                imagePath = ""
                            }

                        }

                    }
                }
            }
            Spacer()
            ZStack {
                Rectangle().foregroundColor(.white)
                if (URL(string: imagePath) == nil) {
                    Image(systemName: "photo").foregroundColor(.black)
                } else {
                    Image(nsImage: NSImage(contentsOf: URL(string: imagePath)!)!).resizable()
                }
            }.frame(width: 150, height: 150)
            Spacer()
            HStack {
                Button(action:{
                    isPresented = false
                }) {
                    Text("Cancel")
                }
                Spacer()
                Button(action:{
                    isPresented = false
                    submit()
                }) {
                    Text("Add Part")
                }
                .disabled(name.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }.padding()
    }
}

struct AddCustomPartView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RebrickableManagerPreview()
        AddCustomPartView(isPresented: .constant(true))
            .environmentObject(manager as RebrickableManager)
    }
}
