//
//  Brick_CollectorApp.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/3/21.
//

import SwiftUI

@main
struct Brick_CollectorApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
