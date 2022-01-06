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
    @AppStorage("colorsLastUpdated")
    private var colorsLastUpated:Int = Int(Date.now.timeIntervalSince1970)
    @State private var importXML = false
    @State private var importLegacy = false
    @State private var importBcc = false
    @State private var exportBcc = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(Globals.rebrickableManager)
                    .environmentObject(appManager)
                    .onAppear(perform: {
                        Task {
                            if Date.now.timeIntervalSince1970 - TimeInterval(colorsLastUpated) > TimeInterval(604800) {
                                await appManager.updateColors()
                            }
                        }
                })
                HStack {}
                .fileImporter(isPresented: $importXML, allowedContentTypes: [.xml], onCompletion: importBricklinkXml)
                HStack {}
                .fileImporter(isPresented: $importLegacy, allowedContentTypes: [.commaSeparatedText], onCompletion: importLegacy)
                HStack {}
                .fileImporter(isPresented: $importBcc, allowedContentTypes: [.data], onCompletion: importBcc)
                HStack {}
                .fileExporter(isPresented: $exportBcc, document: exportBccFile(), contentType: .data, defaultFilename: "collection.bcc", onCompletion: finishExport)
            }
        }.commands {
            CommandGroup(replacing: .newItem) {
                Menu("Import") {
                    Button("Brick Collector...") {
                        importBcc = true
                    }
                    Button("BrickLink XML...") {
                        importXML = true
                    }
                    Button("Legacy CSV...") {
                        importLegacy = true
                    }
                }
                Menu("Export") {
                    Button("Brick Collector...") {
                        exportBcc = true
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
    
    func importBcc(result: Result<URL, Error>) {
        do {
            let selectedFile: URL = try result.get()
            let data = try Data(contentsOf: selectedFile)
            let collection = try JSONDecoder().decode(IOCollection.self, from: data)
            appManager.upsertCollection(collection: collection)
        } catch {
            appManager.issueError(type: .ImportFile, description: "Import Brick Collector Data", error: .FileReadError)
        }

    }
    
    func exportBccFile() -> CollectionFile {
        let context = persistenceController.container.viewContext
        
        do {
            let parts = try context.fetch(Part.fetchRequest())
            let sets = try context.fetch(Kit.fetchRequest())
            let inventories = try context.fetch(InventoryItem.fetchRequest())
            return CollectionFile(parts: parts, sets: sets, inventories: inventories)
        } catch {
            return CollectionFile()
        }
    }
    
    func finishExport(result: Result<URL, Error>) {
        switch result {
        case .success(_):
            return
        case .failure(_):
            appManager.issueError(type: .ExportFile, description: "Export Brick Collector data", error: .FileWriteError)
        }
    }
}
