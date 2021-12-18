//
//  Persistence.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/3/21.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        let newPart = Part(context: viewContext)
        newPart.id = "4106356"
        newPart.name = "Brick 2x4"
        newPart.loose = 1
        newPart.quantity = 1
        newPart.colorId = 1
        let newPart2 = Part(context: viewContext)
        newPart2.id = "300323"
        newPart2.name = "Brick 2x2"
        newPart2.loose = 2
        newPart2.quantity = 2
        newPart2.colorId = 1
        let newColor = PartColor(context: viewContext)
        newColor.id = 1
        newColor.name = "Test Color"
        newColor.hex = "FF0000"
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Brick_Collector")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                Typical reasons for an error here include:
                * The parent directory does not exist, cannot be created, or disallows writing.
                * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                * The device is out of space.
                * The store could not be migrated to the current model version.
                Check the error message to determine what the actual problem was.
                */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }
}
