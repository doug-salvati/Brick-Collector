//
//  CollectionFile.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/4/22.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI

struct CollectionFile: FileDocument {
    static var readableContentTypes = [UTType.data]
    
    var collection:IOCollection = .emptyCollection

    init() { }
    
    init(parts:[Part], sets:[Kit], inventories:[InventoryItem]) {
        collection = IOCollection(parts: parts, sets: sets, inventories: inventories)
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            collection = try JSONDecoder().decode(IOCollection.self, from: data)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(collection)
        return FileWrapper(regularFileWithContents: data)
    }
}
