//
//  ImageLoader.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/24/21.
//

import SwiftUI
import Combine
import Foundation

class ImageLoader: ObservableObject {
    @Published var image:NSImage?
    private let url:URL
    private var operation: AnyCancellable?
    
    init(url:URL) {
        self.url = url
    }
    
    deinit {
        operation?.cancel()
    }
    
    func load() {
        operation = URLSession.shared.dataTaskPublisher(for: url)
            .map({ NSImage(data: $0.data) })
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.image = $0 }
    }
}
