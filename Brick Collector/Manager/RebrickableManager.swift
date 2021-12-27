//
//  RebrickableManager.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/4/21.
//

import Foundation
import SwiftUI

enum RebrickableError: Error {
    case InvalidURL
    case PartRetrievalFailure
    case ColorRetrievalFailure
}

extension RebrickableError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .InvalidURL:
            return NSLocalizedString("Failed to submit request.", comment: "Failed to create URL object")
        case .PartRetrievalFailure:
            return NSLocalizedString("No results found.", comment: "Failed part API call")
        case .ColorRetrievalFailure:
            return NSLocalizedString("Failed to retrieve colors. Check API key and try again.", comment: "Failed color API call")
        }
    }
}

extension Sequence {
    func asyncForEach(
        _ op: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await op(element)
        }
    }
}

struct RebrickableResult<T> {
    var result:T?
    var error:RebrickableError?
    var loading:Bool = false
}

struct ArrayResults<T:Decodable>: Decodable {
    var results:[T]
    
    enum CodingKeys: String, CodingKey {
        case results
    }
    
    init(from decoder:Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        results = try container.decode([T].self, forKey: .results)
    }
}

@MainActor
class RebrickableManager: ObservableObject {
    @AppStorage("apiKey")
    private var key:String = ""
    private var queryParams:String {
        "?key=\(key)"
    }
    @Published var searchedParts:RebrickableResult<[Element]> = RebrickableResult<[Element]>()
    @Published var colors:RebrickableResult<[ElementColor]> = RebrickableResult<[ElementColor]>()
    private static let endpoint = "https://rebrickable.com/api/v3/lego"
    
    func searchParts(byElementId element:String) async {
        let url = URL(string: "\(RebrickableManager.endpoint)/elements/\(element)/\(queryParams)")
        if url == nil {
            let result = RebrickableResult<[Element]>(error: RebrickableError.InvalidURL)
            self.searchedParts = result
        }
        self.searchedParts.loading = true
        var result:RebrickableResult<[Element]>
        do {
            let (data, _) = try await URLSession.shared.data(from: url!)
            let json = try JSONDecoder().decode(Element.self, from: data)
            result = RebrickableResult<[Element]>(result: [json])
        } catch {
            result = RebrickableResult<[Element]>(error: RebrickableError.PartRetrievalFailure)
        }
        self.searchedParts = result
    }
    
    func searchParts(byPartId part:String) async {
        let partUrl = URL(string: "\(RebrickableManager.endpoint)/parts/\(part)/\(queryParams)")
        let colorsUrl = URL(string: "\(RebrickableManager.endpoint)/parts/\(part)/colors/\(queryParams)&page_size=1000")
        if partUrl == nil || colorsUrl == nil {
            let result = RebrickableResult<[Element]>(error: RebrickableError.InvalidURL)
            self.searchedParts = result
        }
        self.searchedParts.loading = true
        var result:RebrickableResult<[Element]>
        var mold:Mold
        var moldColors:[MoldColor]
        do {
            let (partData, _) = try await URLSession.shared.data(from: partUrl!)
            mold = try JSONDecoder().decode(Mold.self, from: partData)
            let (colorData, _) = try await URLSession.shared.data(from: colorsUrl!)
            moldColors = try JSONDecoder().decode(ArrayResults<MoldColor>.self, from: colorData).results
            let elements:[Element] = moldColors.map { moldColor in
                let id = moldColor.elements.first ?? "\(mold.partNum) (\(moldColor.colorName))"
                return Element(id: id, img: moldColor.img, name: mold.name, colorId: moldColor.colorId)
                }
            result = RebrickableResult<[Element]>(result: elements)
        } catch {
            result = RebrickableResult<[Element]>(error: RebrickableError.PartRetrievalFailure)
        }
        self.searchedParts = result
    }
    
    func searchParts(bySetId set:String) async {
        let partUrl = URL(string: "\(RebrickableManager.endpoint)/sets/\(set)/parts/\(queryParams)&page_size=10000")
        if partUrl == nil {
            let result = RebrickableResult<[Element]>(error: RebrickableError.InvalidURL)
            self.searchedParts = result
        }
        self.searchedParts.loading = true
        var result:RebrickableResult<[Element]>
        do {
            let (partData, _) = try await URLSession.shared.data(from: partUrl!)
            var items = try JSONDecoder().decode(ArrayResults<InventoryItem>.self, from: partData).results
            if (items.count == 0) {
                result = RebrickableResult<[Element]>(error: RebrickableError.PartRetrievalFailure)
            } else {
                try await getMinifigs(bySetId: set).asyncForEach { minifig in
                    let minifigParts = try await getParts(byMinifig: minifig.setNum).map { part in
                        return InventoryItem(part: part.part, color: part.color, elementId: part.elementId, quantity: part.quantity * minifig.quantity, isSpare: part.isSpare)
                    }
                    items.append(contentsOf: minifigParts)
                }
                let elements:[Element] = items.filter { !$0.isSpare }.map { item in
                    let id = item.elementId ?? "\(item.part.partNum) (\(item.color.rebrickableName)"
                    return Element(id: id, img: item.part.img!, name: item.part.name, colorId: item.color.id)
                }
                result = RebrickableResult<[Element]>(result: elements)
            }
        } catch {
            result = RebrickableResult<[Element]>(error: RebrickableError.PartRetrievalFailure)
        }
        self.searchedParts = result
    }
    
    func getMinifigs(bySetId set:String) async throws -> [MinifigInventoryItem] {
        let minifigUrl = URL(string: "\(RebrickableManager.endpoint)/sets/\(set)/minifigs/\(queryParams)")
        let (minifigData, _) = try await URLSession.shared.data(from: minifigUrl!)
        return try JSONDecoder().decode(ArrayResults<MinifigInventoryItem>.self, from: minifigData).results
    }
    
    func getParts(byMinifig minifig:String) async throws -> [InventoryItem] {
        let partUrl = URL(string: "\(RebrickableManager.endpoint)/minifigs/\(minifig)/parts/\(queryParams)")
        let (partData, _) = try await URLSession.shared.data(from: partUrl!)
        return try JSONDecoder().decode(ArrayResults<InventoryItem>.self, from: partData).results
    }
    
    func resetParts() {
        self.searchedParts = RebrickableResult<[Element]>()
    }
    
    func getColors(callback: @escaping (RebrickableResult<[ElementColor]>) -> Void) async {
        let url = URL(string: "\(RebrickableManager.endpoint)/colors/\(queryParams)&page_size=200")
        if url == nil {
            let result = RebrickableResult<[ElementColor]>(error: RebrickableError.InvalidURL)
            self.colors = result
        }
        self.colors.loading = true
        var result:RebrickableResult<[ElementColor]>
        do {
            let (data, _) = try await URLSession.shared.data(from: url!)
            let json = try JSONDecoder().decode(ArrayResults<ElementColor>.self, from: data)
            result = RebrickableResult<[ElementColor]>(result: json.results)
        } catch {
            result = RebrickableResult<[ElementColor]>(error: RebrickableError.ColorRetrievalFailure)
        }
        self.colors = result
        callback(result)
    }
}

class RebrickableManagerPreview: RebrickableManager {
    override func searchParts(byElementId element: String) async {
        var result:RebrickableResult<[Element]>
        if (element.isEmpty) {
            result = RebrickableResult<[Element]>(error: RebrickableError.PartRetrievalFailure)
        } else {
            let sample = Element(id: element, img: "foo.png", name: "Preview Element", colorId: 0);
            result = RebrickableResult<[Element]>(result: [sample])
        }
        self.searchedParts = result
    }
    
    override func searchParts(byPartId part: String) async {
        await searchParts(byElementId: "elementId")
    }
    
    override func searchParts(bySetId set: String) async {
        await searchParts(byElementId: "elementId")
    }
    
    override func getColors(callback: @escaping (RebrickableResult<[ElementColor]>) -> Void) async {
        let result = RebrickableResult<[ElementColor]>(result: [])
        self.colors = result
        callback(result)
    }
}
