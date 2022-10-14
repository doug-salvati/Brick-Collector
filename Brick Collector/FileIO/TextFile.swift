//
//  TextFile.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/28/22.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI

struct TextFile: FileDocument {
    static var readableContentTypes:[UTType] = []
    static var writableContentTypes = [UTType.commaSeparatedText, UTType.utf8PlainText]
    
    var content:String = ""

    init() { }
    
    init(_ text:String) {
        content = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            content = String(data: data, encoding: .utf8) ?? ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: Data(content.utf8))
    }
}

