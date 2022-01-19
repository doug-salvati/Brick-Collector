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
    case SetRetrievalFailure
    case ColorRetrievalFailure
}

extension RebrickableError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .InvalidURL:
            return NSLocalizedString("Failed to submit request.", comment: "Failed to create URL object")
        case .PartRetrievalFailure:
            return NSLocalizedString("No results found.", comment: "Failed part API call")
        case .SetRetrievalFailure:
            return NSLocalizedString("No results found.", comment: "Failed set API call")
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
    @Published var searchedParts:RebrickableResult<[RBElement]> = RebrickableResult<[RBElement]>()
    @Published var searchedSet:RebrickableResult<RBSet> = RebrickableResult<RBSet>()
    @Published var searchedInventory:RebrickableResult<[RBInventoryItem]> = RebrickableResult<[RBInventoryItem]>()
    @Published var colors:RebrickableResult<[RBElementColor]> = RebrickableResult<[RBElementColor]>()
    private static let endpoint = "https://rebrickable.com/api/v3/lego"
    
    func searchParts(byElementId element:String) async {
        let url = URL(string: "\(RebrickableManager.endpoint)/elements/\(element)/\(queryParams)")
        if url == nil {
            let result = RebrickableResult<[RBElement]>(error: RebrickableError.InvalidURL)
            self.searchedParts = result
        }
        self.searchedParts.loading = true
        var result:RebrickableResult<[RBElement]>
        do {
            let (data, _) = try await URLSession.shared.data(from: url!)
            let json = try JSONDecoder().decode(RBElement.self, from: data)
            result = RebrickableResult<[RBElement]>(result: [json])
        } catch {
            result = RebrickableResult<[RBElement]>(error: RebrickableError.PartRetrievalFailure)
        }
        self.searchedParts = result
    }
    
    func searchParts(byPartId part:String) async {
        self.searchedParts.loading = true
        var result:RebrickableResult<[RBElement]>
        do {
            let mold = try await getMold(byId: part)
            let moldColors = try await getMoldColors(byMoldId: part)
            let elements:[RBElement] = moldColors.map { moldColor in
                let id = moldColor.elements.first ?? "\(mold.partNum) (\(moldColor.colorName))"
                return RBElement(id: id, img: moldColor.img, name: mold.name, colorId: moldColor.colorId)
                }
            result = RebrickableResult<[RBElement]>(result: elements)
        } catch {
            result = RebrickableResult<[RBElement]>(error: RebrickableError.PartRetrievalFailure)
        }
        self.searchedParts = result
    }
    
    func searchParts(bySetId set:String) async {
        self.searchedParts.loading = true
        var result:RebrickableResult<[RBElement]>
        do {
            let items = try await getInventory(bySetId: set)
            if (items.count == 0) {
                result = RebrickableResult<[RBElement]>(error: RebrickableError.PartRetrievalFailure)
            } else {
                let elements:[RBElement] = items.map { item in
                    let id = item.id
                    return RBElement(id: id, img: item.part.img ?? nil, name: item.part.name, colorId: item.color.id)
                }
                result = RebrickableResult<[RBElement]>(result: elements)
            }
        } catch {
            result = RebrickableResult<[RBElement]>(error: RebrickableError.PartRetrievalFailure)
        }
        self.searchedParts = result
    }
    
    func searchParts(byBricklinkItems items:[BrickLinkXMLItem]) async {
        self.searchedParts.loading = true
        var result:RebrickableResult<[RBElement]>
        var elements:[RBElement] = []
        do {
            let colors = try await getColors()
            try await items.asyncForEach { item in
                sleep(2) // TODO: can we reduce the number of requests to prevent throttling?
                let mold = try await getMold(byBricklinkId: item.id)
                guard mold != nil else { return }
                let moldColors = try await getMoldColors(byMoldId: mold!.partNum)
                let color = colors.first(where: { $0.bricklinkId != nil && String($0.bricklinkId!) == item.colorId })
                guard color != nil else { return }
                let moldColor = moldColors.first(where: { $0.colorId == color!.id })
                guard moldColor != nil else { return }
                let id = moldColor!.elements.first ?? "\(mold!.partNum) (\(moldColor!.colorName))"
                let element = RBElement(id: id, img: moldColor!.img, name: mold!.name, colorId: moldColor!.colorId)
                elements.append(element)
            }
            if elements.isEmpty {
                print("oops")
                result = RebrickableResult<[RBElement]>(error: RebrickableError.PartRetrievalFailure)
            } else {
                result = RebrickableResult<[RBElement]>(result: elements)
            }
        } catch let error {
            print(error)
            result = RebrickableResult<[RBElement]>(error: RebrickableError.PartRetrievalFailure)
        }
        self.searchedParts = result
    }
    
    func searchSet(byId id:String) async {
        self.searchedSet.loading = true
        var result:RebrickableResult<RBSet>
        do {
            let set = try await getSet(byId: id)
            result = RebrickableResult<RBSet>(result: set)
        } catch {
            result = RebrickableResult<RBSet>(error: RebrickableError.SetRetrievalFailure)
        }
        self.searchedSet = result
    }
    
    func searchInventory(bySetId setId:String, spares:Bool = false) async {
        self.searchedInventory.loading = true
        var result:RebrickableResult<[RBInventoryItem]>
        do {
            let items = try await getInventory(bySetId: setId, spares: spares)
            if (items.count == 0) {
                result = RebrickableResult<[RBInventoryItem]>(error: RebrickableError.PartRetrievalFailure)
            } else {
                result = RebrickableResult<[RBInventoryItem]>(result: items)
            }
        } catch {
            result = RebrickableResult<[RBInventoryItem]>(error: RebrickableError.PartRetrievalFailure)
        }
        self.searchedInventory = result
    }
    
    func getMold(byId id:String) async throws -> RBMold {
        let moldUrl = URL(string: "\(RebrickableManager.endpoint)/parts/\(id)/\(queryParams)")
        let (moldData, _) = try await URLSession.shared.data(from: moldUrl!)
        return try JSONDecoder().decode(RBMold.self, from: moldData)
    }
    
    func getMold(byBricklinkId id:String) async throws -> RBMold? {
        let moldUrl = URL(string: "\(RebrickableManager.endpoint)/parts/\(queryParams)&bricklink_id=\(id)")
        let (moldData, _) = try await URLSession.shared.data(from: moldUrl!)
        return try JSONDecoder().decode(ArrayResults<RBMold>.self, from: moldData).results.first
    }
    
    func getMoldColors(byMoldId id:String) async throws -> [RBMoldColor] {
        let colorsUrl = URL(string: "\(RebrickableManager.endpoint)/parts/\(id)/colors/\(queryParams)&page_size=1000")
        let (colorData, _) = try await URLSession.shared.data(from: colorsUrl!)
        return try JSONDecoder().decode(ArrayResults<RBMoldColor>.self, from: colorData).results
    }
    
    func getMinifigs(bySetId set:String) async throws -> [MinifigInventoryItem] {
        let minifigUrl = URL(string: "\(RebrickableManager.endpoint)/sets/\(set)/minifigs/\(queryParams)")
        let (minifigData, _) = try await URLSession.shared.data(from: minifigUrl!)
        return try JSONDecoder().decode(ArrayResults<MinifigInventoryItem>.self, from: minifigData).results
    }
    
    func getInventory(bySetId setId:String, spares:Bool = false) async throws -> [RBInventoryItem] {
        let partUrl = URL(string: "\(RebrickableManager.endpoint)/sets/\(setId)/parts/\(queryParams)&page_size=10000")
        let (partData, _) = try await URLSession.shared.data(from: partUrl!)
        var items = try JSONDecoder().decode(ArrayResults<RBInventoryItem>.self, from: partData).results
        try await getMinifigs(bySetId: setId).asyncForEach { minifig in
            let minifigParts = try await getInventory(byMinifig: minifig.setNum).map { part in
                return RBInventoryItem(part: part.part, color: part.color, elementId: part.id, quantity: part.quantity * minifig.quantity, isSpare: part.isSpare)
            }
            items.append(contentsOf: minifigParts)
        }
        return consolidate(inventory: items.filter { $0.isSpare == spares })
    }
    
    func getInventory(byMinifig minifig:String) async throws -> [RBInventoryItem] {
        let partUrl = URL(string: "\(RebrickableManager.endpoint)/minifigs/\(minifig)/parts/\(queryParams)")
        let (partData, _) = try await URLSession.shared.data(from: partUrl!)
        return try JSONDecoder().decode(ArrayResults<RBInventoryItem>.self, from: partData).results
    }
    
    func getSet(byId id:String) async throws -> RBSet {
        let setUrl = URL(string: "\(RebrickableManager.endpoint)/sets/\(id)/\(queryParams)")
        let (setData, _) = try await URLSession.shared.data(from: setUrl!)
        var set = try JSONDecoder().decode(RBSet.self, from: setData)
        set.theme = try await getTheme(byId: set.themeId)
        return set
    }
    
    func getTheme(byId id:Int) async throws -> String {
        let themeUrl = URL(string: "\(RebrickableManager.endpoint)/themes/\(id)/\(queryParams)")
        let (themeData, _) = try await URLSession.shared.data(from: themeUrl!)
        return try JSONDecoder().decode(RBTheme.self, from: themeData).name
    }
    
    func getColors() async throws -> [RBElementColor] {
        let url = URL(string: "\(RebrickableManager.endpoint)/colors/\(queryParams)&page_size=200")
        let (data, _) = try await URLSession.shared.data(from: url!)
        return try JSONDecoder().decode(ArrayResults<RBElementColor>.self, from: data).results
    }
    
    func resetParts() {
        self.searchedParts = RebrickableResult<[RBElement]>()
    }
    
    func resetSet() {
        self.searchedSet = RebrickableResult<RBSet>()
    }
    
    func updateColors(callback: @escaping (RebrickableResult<[RBElementColor]>) -> Void) async {
        self.colors.loading = true
        var result:RebrickableResult<[RBElementColor]>
        do {
            let colors = try await getColors()
            result = RebrickableResult<[RBElementColor]>(result: colors)
        } catch {
            result = RebrickableResult<[RBElementColor]>(error: RebrickableError.ColorRetrievalFailure)
        }
        self.colors = result
        callback(result)
    }
}

class RebrickableManagerPreview: RebrickableManager {
    override func searchParts(byElementId element: String) async {
        var result:RebrickableResult<[RBElement]>
        if (element.isEmpty) {
            result = RebrickableResult<[RBElement]>(error: RebrickableError.PartRetrievalFailure)
        } else {
            let sample = RBElement(id: element, img: "foo.png", name: "Preview Element", colorId: 0);
            result = RebrickableResult<[RBElement]>(result: [sample])
        }
        self.searchedParts = result
    }
    
    override func searchParts(byPartId part: String) async {
        await searchParts(byElementId: "elementId")
    }
    
    override func searchParts(bySetId set: String) async {
        await searchParts(byElementId: "elementId")
    }
    
    override func updateColors(callback: @escaping (RebrickableResult<[RBElementColor]>) -> Void) async {
        let result = RebrickableResult<[RBElementColor]>(result: [])
        self.colors = result
        callback(result)
    }
}
