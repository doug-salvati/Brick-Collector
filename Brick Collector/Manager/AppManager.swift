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
}

struct AppOperation {
    var type:AppOperationType
    var description:String?
    var done:Bool = false
    var error:Error?
    var dismissed:Bool = false
}

enum AppView {
    case sets
    case parts
}

class AppManager: ObservableObject {
    private var manager:RebrickableManager
    @Published var queue:[UUID:AppOperation] = [:]
    @Published var activeTab:AppView = .parts
    @Published var activePartFeature:Part?
    @Published var activeSetFeature:Kit?
    
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
        await manager.getColors { response in
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
}
