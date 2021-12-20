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
    case JSONParseError
}

extension RebrickableError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .InvalidURL:
            return NSLocalizedString("Failed to submit request.", comment: "Failed to create URL object")
        case .PartRetrievalFailure:
            return NSLocalizedString("Failed to retrieve part. Check API key and try again.", comment: "Failed part API call")
        case .ColorRetrievalFailure:
            return NSLocalizedString("Failed to retrieve colors. Check API key and try again.", comment: "Failed color API call")
        case .JSONParseError:
            return NSLocalizedString("Failed to receive data.", comment: "Response JSON failed to parse")
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

class RebrickableManager: ObservableObject {
    @AppStorage("apiKey")
    private var key:String = ""
    private var queryParams:String {
        "?key=\(key)"
    }
    @Published var searchedPart:RebrickableResult<Element> = RebrickableResult<Element>()
    @Published var colors:RebrickableResult<[ElementColor]> = RebrickableResult<[ElementColor]>()
    private static let endpoint = "https://rebrickable.com/api/v3/lego"
    
    func searchPart(byElementId element:String) {
        let url = URL(string: "\(RebrickableManager.endpoint)/elements/\(element)/\(queryParams)")
        if url == nil {
            let result = RebrickableResult<Element>(error: RebrickableError.InvalidURL)
            DispatchQueue.main.async {
                self.searchedPart = result
            }
        }
        DispatchQueue.main.async {
            self.searchedPart.loading = true
        }
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            var result:RebrickableResult<Element>
            if error == nil && data != nil {
                do {
                    let json = try JSONDecoder().decode(Element.self, from: data!)
                    result = RebrickableResult<Element>(result: json)
                } catch {
                    result = RebrickableResult<Element>(error: RebrickableError.JSONParseError)
                }
            } else {
                result = RebrickableResult<Element>(error: RebrickableError.PartRetrievalFailure)
            }
            DispatchQueue.main.async {
                self.searchedPart = result
            }
        }.resume()
    }
    
    func getColors(callback: @escaping (RebrickableResult<[ElementColor]>) -> Void) {
        let url = URL(string: "\(RebrickableManager.endpoint)/colors/\(queryParams)&page_size=200")
        if url == nil {
            let result = RebrickableResult<[ElementColor]>(error: RebrickableError.InvalidURL)
            DispatchQueue.main.async {
                self.colors = result
            }
        }
        DispatchQueue.main.async {
            self.colors.loading = true
        }
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            var result:RebrickableResult<[ElementColor]>
            if error == nil && data != nil {
                do {
                    let json = try JSONDecoder().decode(ArrayResults<ElementColor>.self, from: data!)
                    result = RebrickableResult<[ElementColor]>(result: json.results)
                } catch {
                    result = RebrickableResult<[ElementColor]>(error: RebrickableError.JSONParseError)
                }
            } else {
                result = RebrickableResult<[ElementColor]>(error: RebrickableError.ColorRetrievalFailure)
            }
            DispatchQueue.main.async {
                self.colors = result
                callback(result)
            }
        }.resume()
    }
}

class RebrickableManagerPreview: RebrickableManager {
    override func searchPart(byElementId element: String) {
        var result:RebrickableResult<Element>
        if (element.isEmpty) {
            result = RebrickableResult<Element>(error: RebrickableError.PartRetrievalFailure)
        } else {
            let sample = Element(id: element, img: "foo.png", name: "Preview Element", colorId: 0);
            result = RebrickableResult<Element>(result: sample)
        }
        self.searchedPart = result
    }
    override func getColors(callback: @escaping (RebrickableResult<[ElementColor]>) -> Void) {
        let result = RebrickableResult<[ElementColor]>(result: [])
        self.colors = result
        callback(result)
    }
}
