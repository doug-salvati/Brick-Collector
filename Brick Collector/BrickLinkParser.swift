//
//  BrickLinkParser.swift
//  Brick Collector
//
//  Created by Doug Salvati on 12/31/21.
//

import Foundation
import SwiftUI

struct BrickLinkXMLItem {
    var id:String
    var colorId:String
}

class BrickLinkParser: XMLParser {
    var bricklinkItems:[BrickLinkXMLItem] = []
    var capturingId = false
    var capturingColor = false
    var buffer:BrickLinkXMLItem = BrickLinkXMLItem(id: "", colorId: "")
    
    override init(data: Data) {
        super.init(data: data)
        self.delegate = self
    }
}

extension BrickLinkParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        switch elementName {
        case "ITEM":
            buffer = BrickLinkXMLItem(id: "", colorId: "")
        case "ITEMID":
            capturingId = true
        case "COLOR":
            capturingColor = true
        default:
            return
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "ITEM":
            bricklinkItems.append(buffer)
        case "ITEMID":
            capturingId = false
        case "COLOR":
            capturingColor = false
        default:
            return
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters characters: String) {
        if (capturingId) {
            buffer.id += characters
        }
        if (capturingColor) {
            buffer.colorId += characters
        }
    }
}
