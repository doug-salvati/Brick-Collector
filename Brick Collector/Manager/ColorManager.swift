//
//  ColorManager.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/16/21.
//

import Foundation
import SwiftUI

class ColorManager {
    static func updateColors(using manager:RebrickableManager) {
        print("updating colors...")
        manager.getColors { response in
            // TODO: warn user
            guard response.error == nil else {
                print(response.error!.localizedDescription)
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
                } catch let error {
                    print(error.localizedDescription)
                    return
                }
            }
        }
    }

}
