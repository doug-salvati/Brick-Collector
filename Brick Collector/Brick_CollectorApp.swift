//
//  Brick_CollectorApp.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/3/21.
//

import SwiftUI

@MainActor
enum Globals {
    static let rebrickableManager = RebrickableManager()
}
var appManager = AppManager(using: Globals.rebrickableManager)

@main
struct Brick_CollectorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    @State private var importXML = false
    @State private var importLegacy = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(Globals.rebrickableManager)
                .environmentObject(appManager)
                .onAppear(perform: {
                    // TODO: update colors once a week
                })
                .fileImporter(isPresented: $importXML, allowedContentTypes: [.xml], onCompletion: importBricklinkXml)
                .fileImporter(isPresented: $importLegacy, allowedContentTypes: [.commaSeparatedText], onCompletion: importLegacy)
        }.commands {
            CommandGroup(replacing: .newItem) {
                Menu("Import") {
                    Button("BrickLink XML...") {
                        importXML = true
                    }
                    Button("Legacy CSV...") {
                        importLegacy = true
                    }
                }
            }
            CommandGroup(before: .toolbar) {
                Button("Parts") {
                    appManager.activeTab = .parts
                }.keyboardShortcut("1")
                Button("Sets") {
                    appManager.activeTab = .sets
                }.keyboardShortcut("2")
                Divider()
            }
            CommandMenu("Collection") {
                Button("Add Part") {
                    appManager.activeTab = .parts
                    appManager.showAdditionModal = true
                }.keyboardShortcut("P")
                Button("Add Set") {
                    appManager.activeTab = .sets
                    appManager.showAdditionModal = true
                }.keyboardShortcut("S")
            }
        }
        #if os(macOS)
        Settings {
            Preferences().environmentObject(appManager)
        }
        #endif
    }
    
    func importBricklinkXml(result: Result<URL, Error>) {
        do {
            let selectedFile: URL = try result.get()
            let input = try Data(contentsOf: selectedFile)
            let parser = BrickLinkParser(data: input)
            if parser.parse() {
                appManager.importing = true
                appManager.activeTab = .parts
                appManager.showAdditionModal = true
                DispatchQueue(label: "loadXML").async {
                    Task {
                        await Globals.rebrickableManager.searchParts(byBricklinkItems: parser.bricklinkItems)
                    }
                }
            } else {
                appManager.issueError(type: .ImportFile, description: "Import \(selectedFile.relativePath.split(separator: "/").last ?? "Bricklink XML")", error: .FileReadError)
            }
        } catch {
            appManager.issueError(type: .ImportFile, description: "Import BrickLink XML", error: .FileReadError)
        }
    }
    
    func importLegacy(result: Result<URL, Error>) {
        do {
            let selectedFile: URL = try result.get()
            let data = try String(contentsOf: selectedFile)
            var rows = data.split(whereSeparator: \.isNewline)
            rows.remove(at: 0)
            print("Found \(rows.count) parts to add")
            print("====================")
            var counter = 1
            rows.forEach { row in
                let values = row.split(separator: ";")
                let id = String(values[0])
                let name = String(values[1])
                let color = String(values[2])
                let img = String(values[3])
                let loose = String(values[5])
                print("[\(counter)/\(rows.count)] \(loose)x \(color) \(id) \(name)")
                appManager.insertCustomPart(id: id, name: name, color: color, img: img, loose: loose)
                counter += 1
            }
        } catch {
            appManager.issueError(type: .ImportFile, description: "Import Legacy Data", error: .FileReadError)
        }
    }
}
