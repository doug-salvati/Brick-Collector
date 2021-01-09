//
//  RebrickableManager.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/4/21.
//

import Foundation

enum RebrickableError: Error {
    case InvalidURL
    case PartRetrievalFailure
    case ColorRetrievalFailure
    case JSONParseError
}

struct RebrickableResult<T> {
    var result:T?
    var error:RebrickableError?
}

class RebrickableManager: ObservableObject {
    private var key:String
    private var queryParams:String {
        "?key=\(key)"
    }
    @Published var searchedPart:RebrickableResult<Element>?
    @Published var colors:RebrickableResult<[ElementColor]>?
    private static let endpoint = "https://rebrickable.com/api/v3/lego"
    
    init(withAPIKey key: String) {
        self.key = key
    }
    
    func searchPart(byElementId element:String) {
        let url = URL(string: "\(RebrickableManager.endpoint)/elements/\(element)/\(queryParams)")
        if url == nil {
            let result = RebrickableResult<Element>(error: RebrickableError.InvalidURL)
            DispatchQueue.main.async {
                self.searchedPart = result
            }
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
    
    func getColors() {
        let url = URL(string: "\(RebrickableManager.endpoint)/colors/\(queryParams)")
        if url == nil {
            let result = RebrickableResult<[ElementColor]>(error: RebrickableError.InvalidURL)
            DispatchQueue.main.async {
                self.colors = result
            }
        }
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            var result:RebrickableResult<[ElementColor]>
            if error == nil && data != nil {
                do {
                    let json = try JSONDecoder().decode([ElementColor].self, from: data!)
                    result = RebrickableResult<[ElementColor]>(result: json)
                } catch {
                    result = RebrickableResult<[ElementColor]>(error: RebrickableError.JSONParseError)
                }
            } else {
                result = RebrickableResult<[ElementColor]>(error: RebrickableError.ColorRetrievalFailure)
            }
            DispatchQueue.main.async {
                self.colors = result
            }
        }.resume()
    }
}

class RebrickableManagerPreview: RebrickableManager {
    init() {
        super.init(withAPIKey: "preview")
    }
    
    override func searchPart(byElementId element: String) {
        var result:RebrickableResult<Element>
        print(element)
        if (element.isEmpty) {
            result = RebrickableResult<Element>(error: RebrickableError.PartRetrievalFailure)
        } else {
            let sample = Element(id: element, img: "foo.png", name: "Preview Element");
            result = RebrickableResult<Element>(result: sample)
        }
        self.searchedPart = result
    }
}
