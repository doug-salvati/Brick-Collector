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
}

struct AppOperation {
    var type:AppOperationType
    var description:String?
    var done:Bool = false
    var error:Error?
}

class AppManager: ObservableObject {
    private var manager:RebrickableManager
    @Published var queue:[UUID:AppOperation] = [:]
    
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
    
    func isLoading() -> Bool {
        return queue.filter({!$0.value.done}).count > 0
    }
    
    func isLoading(type:AppOperationType) -> Bool {
        return queue.filter({!$0.value.done && $0.value.type == type}).count > 0
    }
    
    func updateColors() {
        let id:UUID = self.queue(op: AppOperation(type: .UpdateColors))
        manager.getColors { response in
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

}
