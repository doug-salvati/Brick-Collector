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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(Globals.rebrickableManager)
                .environmentObject(appManager)
                .onAppear(perform: {
                    // TODO: update colors once a week
                })
        }.commands {
            CommandGroup(replacing: .newItem, addition: { })
        }
        #if os(macOS)
        Settings {
            Preferences().environmentObject(appManager)
        }
        #endif
    }
}
