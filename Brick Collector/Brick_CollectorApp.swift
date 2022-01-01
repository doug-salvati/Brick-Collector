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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(Globals.rebrickableManager)
                .environmentObject(appManager)
                .onAppear(perform: {
                    // TODO: update colors once a week
                })
                .fileImporter(isPresented: $importXML, allowedContentTypes: [.xml]) { result in
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
        }.commands {
            CommandGroup(replacing: .newItem) {
                Menu("Import") {
                    Button("BrickLink XML") {
                        importXML = true
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
}
