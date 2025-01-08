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

@main
struct Brick_CollectorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    @AppStorage("colorsLastUpdated")
    private var colorsLastUpated:Int = 0
    @AppStorage("zoomLevel")
    private var zoomLevel:Int = 4
    @State private var importXML = false
    @State private var importBcc = false
    @State private var exportBcc = false
    @State private var exportSetCsv = false
    @State private var exportPartCsv = false
    
    var appManager = AppManager(using: Globals.rebrickableManager)
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(Globals.rebrickableManager)
                    .environmentObject(appManager)
                    .onAppear(perform: {
                        Task {
                            // update colors weekly
                            if Int(Date.now.timeIntervalSince1970) - colorsLastUpated > 604800 {
                                await appManager.updateColors()
                            }
                        }
                })
                HStack {}
                    .fileImporter(isPresented: $importXML, allowedContentTypes: [.xml], onCompletion: importBricklinkXml)
                HStack {}
                    .fileImporter(isPresented: $importBcc, allowedContentTypes: [.data], onCompletion: importBcc)
                HStack {}
                    .fileExporter(isPresented: $exportBcc, document: exportBccFile(), contentType: .data, defaultFilename: "collection.bcc", onCompletion: finishExport)
                HStack {}
                    .fileExporter(isPresented: $exportPartCsv, document: exportPartCsvFile(), contentType: .commaSeparatedText, defaultFilename: "elements.csv", onCompletion: finishExport)
                HStack {}
                    .fileExporter(isPresented: $exportSetCsv, document: exportSetCsvFile(), contentType: .commaSeparatedText, defaultFilename: "sets.csv", onCompletion: finishExport)
            }
        }.commands {
            CommandGroup(replacing: .newItem) {
                Menu("Import") {
                    Button("Brick Collector...") {
                        importBcc = true
                    }.keyboardShortcut("O")
                    Menu("Parts") {
                        Button("BrickLink XML...") {
                            importXML = true
                        }
                    }
                }
                Menu("Export") {
                    Button("Brick Collector...") {
                        exportBcc = true
                    }.keyboardShortcut("E")
                    Menu("Parts") {
                        Button("Comma Separated...") {
                            exportPartCsv = true
                        }
                    }
                    Menu("Sets") {
                        Button("Comma Separated...") {
                            exportSetCsv = true
                        }
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
                Button("Larger Tiles") {
                    zoomLevel = max(zoomLevel - 1, 1)
                }.keyboardShortcut("+")
                Button("Smaller Tiles") {
                    zoomLevel = min(zoomLevel + 1, 8)
                }.keyboardShortcut("-")
                Button("Default Tiles") {
                    zoomLevel = 4
                }.keyboardShortcut("0")
                Divider()
            }
            CommandMenu("Collection") {
                Button("Add Part...") {
                    appManager.activeTab = .parts
                    appManager.setActiveModal(.add)
                }.keyboardShortcut("P")
                Button("Add Set...") {
                    appManager.activeTab = .sets
                    appManager.setActiveModal(.add)
                }.keyboardShortcut("S")
                Divider()
                Button("Add Custom Part...") {
                    appManager.activeTab = .parts
                    appManager.setActiveModal(.addCustom)
                }
            }
            CommandGroup(replacing: .help) {
                Link("Brick Collector Help", destination: URL(string: "https://github.com/doug-salvati/Brick-Collector/tree/main#readme")!)
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
            if (selectedFile.startAccessingSecurityScopedResource()) {
                let input = try Data(contentsOf: selectedFile)
                let parser = BrickLinkParser(data: input)
                if parser.parse() {
                    appManager.importing = true
                    appManager.activeTab = .parts
                    appManager.setActiveModal(.add)
                    DispatchQueue(label: "loadXML").async {
                        Task {
                            await Globals.rebrickableManager.searchParts(byBricklinkItems: parser.bricklinkItems)
                        }
                    }
                } else {
                    appManager.issueError(type: .ImportFile, description: "Import \(selectedFile.relativePath.split(separator: "/").last ?? "Bricklink XML")", error: .FileReadError)
                }
            } else {
                appManager.issueError(type: .ImportFile, description: "Import BrickLink XML", error: .FileReadError)
            }
            selectedFile.stopAccessingSecurityScopedResource();
        } catch {
            appManager.issueError(type: .ImportFile, description: "Import BrickLink XML", error: .FileReadError)
        }
    }
    
    func importBcc(result: Result<URL, Error>) {
        do {
            let selectedFile: URL = try result.get()
            if (selectedFile.startAccessingSecurityScopedResource()) {
                let data = try Data(contentsOf: selectedFile)
                let collection = try JSONDecoder().decode(IOCollection.self, from: data)
                appManager.upsertCollection(collection: collection)
            } else {
                appManager.issueError(type: .ImportFile, description: "Import Brick Collector Data", error: .FileReadError)
            }
            selectedFile.stopAccessingSecurityScopedResource();
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
    
    func exportPartCsvFile() -> TextFile {
        let context = persistenceController.container.viewContext
        
        do {
            let parts = try context.fetch(Part.fetchRequest())
            let fields = "\"element\",\"quantity\", \"name\",\"color id\"\n"
            let content = parts.reduce(fields) { csv, part in
                return csv + "\"\(part.id ?? "")\",\"\(part.quantity)\",\"\(part.name?.replacingOccurrences(of: "\"", with: "\\\"") ?? "")\",\"\(part.colorId)\"\n"
            }
            return TextFile(content)
        } catch {
            return TextFile()
        }
    }
    
    func exportSetCsvFile() -> TextFile {
        let context = persistenceController.container.viewContext
        
        do {
            let sets = try context.fetch(Kit.fetchRequest())
            let fields = "\"set number\",\"quantity\", \"name\",\"theme\",\"part count\"\n"
            let content = sets.reduce(fields) { csv, kit in
                return csv + "\"\(kit.id ?? "")\",\"\(kit.quantity)\",\"\(kit.name?.replacingOccurrences(of: "\"", with: "\\\"") ?? "")\",\"\(kit.theme ?? "")\",\"\(kit.partCount)\"\n"
            }
            return TextFile(content)
        } catch {
            return TextFile()
        }
    }
    
    func finishExport(result: Result<URL, Error>) {
        switch result {
        case .success(_):
            return
        case .failure(_):
            appManager.issueError(type: .ExportFile, description: "Export", error: .FileWriteError)
        }
    }
}
