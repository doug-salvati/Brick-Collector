//
//  Brick_CollectorApp.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/3/21.
//

import SwiftUI

var rebrickableManager = RebrickableManager()
var appManager = AppManager(using: rebrickableManager)

@main
struct Brick_CollectorApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(rebrickableManager)
                .environmentObject(appManager)
                .onAppear(perform: {
                    // TODO: update colors once a week
                })
        }
        #if os(macOS)
        Settings {
            Preferences().environmentObject(appManager)
        }
        #endif
    }
}
