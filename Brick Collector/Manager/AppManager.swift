//
//  ColorManager.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/16/21.
//

import Foundation
import SwiftUI

enum AppOperationType {
    case UpdateColors
    case UpsertPart
    case UpsertSet
    case DownloadImagesForSet
    case UpdatePartQuantity
    case UpdateSetQuantity
    case DeleteSet
    case DeletePart
    case ImportFile
    case ExportFile
    case ImportCollection
}

struct AppOperation {
    var type:AppOperationType
    var description:String?
    var done:Bool = false
    var error:Error?
    var dismissed:Bool = false
}

enum AppView:String {
    case sets = "Sets"
    case parts = "Parts"
}

enum AppError: Error {
    case DeletingUsedPart
    case FileReadError
    case FileWriteError
}

extension AppError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .DeletingUsedPart:
            return NSLocalizedString("Can't delete part because it's being used by a set.", comment: "Refuse to delete parts that aren't loose")
        case .FileReadError:
            return NSLocalizedString("Unable to import the file.", comment: "Error parsing XML")
        case .FileWriteError:
            return NSLocalizedString("Unable to export the file", comment: "Error writing to BCC file")
        }
    }
}


class AppManager: ObservableObject {
    private var manager:RebrickableManager
    @Published var queue:[UUID:AppOperation] = [:]
    @Published var activeTab:AppView = .parts
    @Published var activePartFeature:Part?
    @Published var activeSetFeature:Kit?
    @Published var showAdditionModal:Bool = false
    @Published var importing = false
    @AppStorage("colorsLastUpdated")
    private var colorsLastUpdated:Int = 0
    @AppStorage("jumpToNewSet")
    private var jumpToNewSet:Bool = true
    
    init(using manager:RebrickableManager) {
        self.manager = manager
    }
    
    private func queue(op:AppOperation) -> UUID {
        let uuid:UUID = UUID()
        DispatchQueue.main.async {
            self.queue[uuid] = op
        }
        return uuid
    }
    
    private func finish(opId:UUID) {
        var op:AppOperation? = self.queue[opId]
        if op != nil {
            op!.done = true
            op!.dismissed = true
            DispatchQueue.main.async {
                self.queue[opId] = op
            }
        }
    }
    
    private func finish(opId:UUID, withError error:Error) {
        var op:AppOperation? = self.queue[opId]
        if op != nil {
            op!.done = true
            op!.error = error
            DispatchQueue.main.async {
                self.queue[opId] = op
            }
        }
    }
    
    func dismiss(opId:UUID) {
        var op:AppOperation? = self.queue[opId]
        if op != nil {
            op!.dismissed = true
            DispatchQueue.main.async {
                self.queue[opId] = op
            }
        }
    }
    
    func issueError(type:AppOperationType, description:String, error:AppError) {
        let op = AppOperation(type: type, description: description, done: true, error: error)
        let uuid:UUID = UUID()
        DispatchQueue.main.async {
            self.queue[uuid] = op
        }
    }
    
    func isLoading() -> Bool {
        return queue.filter({!$0.value.done}).count > 0
    }
    
    func isLoading(type:AppOperationType) -> Bool {
        return queue.filter({!$0.value.done && $0.value.type == type}).count > 0
    }
    
    func hasError() -> Bool {
        return queue.filter({!$0.value.dismissed && $0.value.error != nil}).count > 0
    }
    
    func updateColors() async {
        let id:UUID = self.queue(op: AppOperation(type: .UpdateColors, description: "Get colors"))
        await manager.updateColors { response in
            guard response.error == nil else {
                DispatchQueue.main.async {
                    self.finish(opId: id, withError: response.error!)
                }
                return
            }
            
            let context = PersistenceController.shared.container.viewContext
            for color in response.result! {
                let newColor = PartColor(context: context)
                newColor.id = Int64(color.id)
                newColor.hex = color.hex
                newColor.name = color.name
                newColor.bricklinkName = color.bricklinkName
                newColor.rebrickableName = color.rebrickableName
            }
            DispatchQueue.main.async {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "PartColor")
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                do {
                    try context.execute(deleteRequest)
                    try context.save()
                    self.colorsLastUpdated = Int(Date.now.timeIntervalSince1970)
                    self.finish(opId: id)
                } catch let error {
                    self.finish(opId: id, withError: error)
                    return
                }
            }
        }
    }
    
    func downloadImages(forSet setId:String, withParts images:[String:String]) {
        let id:UUID = self.queue(op: AppOperation(type: .DownloadImagesForSet, description: "Downloading images for set \(setId)"))
        let context = PersistenceController.shared.container.viewContext
        var downloadedImages:[String:Data] = [:]
        images.keys.forEach { partId in
            let img = try? Data(contentsOf: URL(string: images[partId]!)!)
            if img != nil {
                downloadedImages[partId] = img!
            }
        }
        DispatchQueue.main.async {
            do {
                downloadedImages.keys.forEach { partId in
                    let request: NSFetchRequest<Part> = Part.fetchRequest()
                    request.predicate = NSPredicate(format: "id LIKE %@", partId)
                    let part = try? context.fetch(request).first
                    guard part != nil else { return }
                    part!.img = downloadedImages[partId]
                }
                try context.save()
                self.finish(opId: id)
            } catch let error {
                self.finish(opId: id, withError: error)
            }
        }
    }

    func upsertParts(elements:[RBElement]) {
        let id:UUID = self.queue(op: AppOperation(type: .UpsertPart, description: "Insert part"))
        let context = PersistenceController.shared.container.viewContext
        elements.forEach { element in
            let request: NSFetchRequest<Part> = Part.fetchRequest()
            request.predicate = NSPredicate(format: "id LIKE %@", element.id)
            var existingPart:Part? = nil
            do {
                existingPart = try context.fetch(request).first
            } catch let error {
                DispatchQueue.main.async {
                    self.finish(opId: id, withError: error)
                }
                return
            }
            if existingPart != nil {
                existingPart!.quantity += 1
                existingPart!.loose += 1
            } else {
                let newPart = Part(context: context)
                newPart.id = element.id
                newPart.name = element.name
                newPart.colorId = Int64(element.colorId)
                newPart.quantity = 1
                newPart.loose = 1
                newPart.img = element.img == nil ? nil : try? Data(contentsOf: URL(string: element.img!)!)
            }
        }

        DispatchQueue.main.async {
            do {
                try context.save()
                self.finish(opId: id)
            } catch let error {
                self.finish(opId: id, withError: error)
            }
        }

    }
    
    func insertCustomPart(id:String, name:String, color:String, img:String, loose:String) {
        let context = PersistenceController.shared.container.viewContext
        let newPart = Part(context: context)
        newPart.id = id
        newPart.name = name
        let partCount = Int64(loose)
        if partCount != nil {
            newPart.quantity = partCount!
            newPart.loose = partCount!
        } else {
            print(" - unable to read part quantity")
            return
        }
        
        let fetchRequest = PartColor.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "rebrickableName == %@", color)
        do {
            let result:PartColor? = try context.fetch(fetchRequest).first
            if result != nil {
                newPart.colorId = result!.id
            } else {
                print(" - unrecognized color")
            }
        } catch {
            print(" - failed to search for color")
        }
        
        if img != "no_img.png" {
            let imgUrl = URL(fileURLWithPath: "/Library/Application Support/com.dsalvati.brickcollector/part_images/\(img)")
            do {
                let imgData = try Data(contentsOf: imgUrl)
                newPart.img = imgData
            } catch {
                print(" - unable to transfer image data, leaving as no img")
            }
        }
        
        DispatchQueue.main.async {
            do {
                try context.save()
            } catch {
                print("unable to save part \(id)")
            }
        }
    }
        
    func upsertSet(_ set:RBSet, containingParts parts:[RBInventoryItem]) {
        let id:UUID = self.queue(op: AppOperation(type: .UpsertSet, description: "Insert set"))
        let context = PersistenceController.shared.container.viewContext
        
        let request: NSFetchRequest<Kit> = Kit.fetchRequest()
        request.predicate = NSPredicate(format: "id LIKE %@", set.id)
        var existingKit:Kit? = nil
        var kit:Kit
        do {
            existingKit = try context.fetch(request).first
        } catch let error {
            DispatchQueue.main.async {
                self.finish(opId: id, withError: error)
            }
            return
        }
        if existingKit != nil {
            existingKit!.quantity += 1
            kit = existingKit!
        } else {
            let newKit = Kit(context: context)
            newKit.id = set.id
            newKit.name = set.name
            newKit.theme = set.theme!
            newKit.quantity = 1
            newKit.partCount = Int64(set.partCount)
            newKit.img = set.img == nil ? nil : try? Data(contentsOf: URL(string: set.img!)!)
            kit = newKit
        }
        
        parts.forEach { item in
            let request: NSFetchRequest<Part> = Part.fetchRequest()
            request.predicate = NSPredicate(format: "id LIKE %@", item.id)
            var existingPart:Part? = nil
            var part:Part
            do {
                existingPart = try context.fetch(request).first
            } catch let error {
                DispatchQueue.main.async {
                    self.finish(opId: id, withError: error)
                }
                return            }
            if existingPart != nil {
                existingPart!.quantity += Int64(item.quantity)
                part = existingPart!
            } else {
                let newPart = Part(context: context)
                newPart.id = item.id
                newPart.name = item.part.name
                newPart.colorId = Int64(item.color.id)
                newPart.quantity = Int64(item.quantity)
                newPart.loose = 0
                // add img later asynchronously
                part = newPart
            }
            if existingKit == nil {
                let newInventoryItem = InventoryItem(context: context)
                newInventoryItem.kit = kit
                newInventoryItem.quantity = Int64(item.quantity)
                newInventoryItem.part = part
            }
        }
        
        var imageMap:[String:String] = [:]
        parts.forEach { item in
            imageMap[item.id] = item.part.img
        }
        
        let group = DispatchGroup()
        group.enter()
        
        DispatchQueue.main.async {
            do {
                try context.save()
                self.finish(opId: id)
                if self.jumpToNewSet {
                    self.activeTab = .sets
                    self.activeSetFeature = kit
                }
            } catch let error {
                self.finish(opId: id, withError: error)
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            DispatchQueue(label: "downloadImage").async {
                self.downloadImages(forSet: set.id, withParts: imageMap)
            }
        }
    }
    
    func upsertSpares(spares:[RBInventoryItem]) {
        let id:UUID = self.queue(op: AppOperation(type: .UpsertSet, description: "Insert set spares"))
        let context = PersistenceController.shared.container.viewContext
                
        spares.forEach { item in
            let request: NSFetchRequest<Part> = Part.fetchRequest()
            request.predicate = NSPredicate(format: "id LIKE %@", item.id)
            var existingPart:Part? = nil
            do {
                existingPart = try context.fetch(request).first
            } catch let error {
                DispatchQueue.main.async {
                    self.finish(opId: id, withError: error)
                }
                return            }
            if existingPart != nil {
                existingPart!.quantity += Int64(item.quantity)
                existingPart!.loose += Int64(item.quantity)
            } else {
                let newPart = Part(context: context)
                newPart.id = item.id
                newPart.name = item.part.name
                newPart.colorId = Int64(item.color.id)
                newPart.quantity = Int64(item.quantity)
                newPart.loose = Int64(item.quantity)
                // add img later asynchronously
            }
        }
        
        var imageMap:[String:String] = [:]
        spares.forEach { item in
            imageMap[item.id] = item.part.img
        }
        
        let group = DispatchGroup()
        group.enter()
        
        DispatchQueue.main.async {
            do {
                try context.save()
                self.finish(opId: id)
            } catch let error {
                self.finish(opId: id, withError: error)
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            DispatchQueue(label: "downloadImage").async {
                self.downloadImages(forSet: "spare parts", withParts: imageMap)
            }
        }
    }
    
    func upsertCollection(collection: IOCollection) {
        let context = PersistenceController.shared.container.viewContext
        let id:UUID = self.queue(op: AppOperation(type: .ImportCollection, description: "Import Brick Collector Collection"))
        do {
            let newParts = try collection.parts.compactMap(self.upsertPart)
            let newSets = try collection.sets.compactMap(self.upsertSet)
            collection.inventories.forEach { item in
                let newSet = newSets.first(where: { $0.id == item.setId })
                let newPart = newParts.first(where: { $0.id == item.partId })
                guard newSet != nil && newPart != nil else { return }
                let newInventoryItem = InventoryItem(context: context)
                newInventoryItem.kit = newSet
                newInventoryItem.quantity = Int64(item.quantity)
                newInventoryItem.part = newPart
            }
        } catch let error {
            self.finish(opId: id, withError: error)
        }
        
        DispatchQueue.main.async {
            do {
                try context.save()
                self.finish(opId: id)
            } catch let error {
                self.finish(opId: id, withError: error)
            }
        }
    }

    
    // IOCollection based upsert methods
    private func upsertPart(_ part:IOPart) throws -> Part? {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<Part> = Part.fetchRequest()
        request.predicate = NSPredicate(format: "id LIKE %@", part.id)
        let existingPart = try context.fetch(request).first
        if existingPart != nil {
            existingPart!.quantity += Int64(part.quantity)
            existingPart!.loose += Int64(part.loose)
            return nil
        } else {
            let newPart = Part(context: context)
            newPart.quantity = Int64(part.quantity)
            newPart.loose = Int64(part.loose)
            newPart.id = part.id
            newPart.name = part.name
            newPart.colorId = Int64(part.colorId)
            newPart.img = part.img
            return newPart
        }
    }
    private func upsertSet(_ kit:IOSet) throws -> Kit? {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<Kit> = Kit.fetchRequest()
        request.predicate = NSPredicate(format: "id LIKE %@", kit.id)
        let existingSet = try context.fetch(request).first
        if existingSet != nil {
            existingSet!.quantity += Int64(kit.quantity)
            return nil
        } else {
            let newKit = Kit(context: context)
            newKit.id = kit.id
            newKit.name = kit.name
            newKit.theme = kit.theme
            newKit.quantity = Int64(kit.quantity)
            newKit.partCount = Int64(kit.partCount)
            newKit.img = kit.img
            return newKit
        }
    }

    func adjustQuantity(of part:Part, by difference:Int64) {
        let id:UUID = self.queue(op: AppOperation(type: .UpdatePartQuantity, description: "Updating quantity of part \(part.id!)"))
        let context = PersistenceController.shared.container.viewContext

        let change = max(-part.loose, difference)
        part.quantity += change
        part.loose += change

        DispatchQueue.main.async {
            do {
                try context.save()
                self.finish(opId: id)
            } catch let error {
                self.finish(opId: id, withError: error)
            }
        }
    }
    
    func adjustQuantity(of kit:Kit, by difference:Int64) {
        let id:UUID = self.queue(op: AppOperation(type: .UpdateSetQuantity, description: "Updating quantity of set \(kit.id!)"))
        let context = PersistenceController.shared.container.viewContext

        let change = max(-kit.quantity, difference)
        kit.quantity += change
        
        let inventory = kit.inventory!.allObjects as! [InventoryItem]
        inventory.forEach { item in
            item.part!.quantity += change * item.quantity
        }

        DispatchQueue.main.async {
            do {
                try context.save()
                self.finish(opId: id)
            } catch let error {
                self.finish(opId: id, withError: error)
            }
        }
    }
    
    func delete(set kit:Kit) {
        let id:UUID = self.queue(op: AppOperation(type: .UpdateSetQuantity, description: "Deleting set \(kit.id!)"))
        let context = PersistenceController.shared.container.viewContext

        let inventory = kit.inventory!.allObjects as! [InventoryItem]
        inventory.forEach { item in
            let part = item.part!
            part.quantity -= kit.quantity * item.quantity
            if (part.quantity == 0) {
                context.delete(part)
            }
            context.delete(item)
        }
        context.delete(kit)
        
        DispatchQueue.main.async {
            do {
                try context.save()
                self.finish(opId: id)
            } catch let error {
                self.finish(opId: id, withError: error)
            }
        }
    }
    
    func delete(part:Part) {
        let id:UUID = self.queue(op: AppOperation(type: .UpdateSetQuantity, description: "Deleting part \(part.id!)"))
        let context = PersistenceController.shared.container.viewContext

        if (part.quantity != part.loose) {
            self.finish(opId: id, withError: AppError.DeletingUsedPart)
        }
        context.delete(part)
        
        DispatchQueue.main.async {
            do {
                try context.save()
                self.finish(opId: id)
            } catch let error {
                self.finish(opId: id, withError: error)
            }
        }
    }
}
