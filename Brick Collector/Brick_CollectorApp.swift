//
//  Brick_CollectorApp.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/3/21.
//

import SwiftUI

var manager = RebrickableManager()

@main
struct Brick_CollectorApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(manager)
        }
        #if os(macOS)
        Settings {
            Preferences()
        }
        #endif
    }
}
