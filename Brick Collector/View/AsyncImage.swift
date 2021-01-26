//
//  AsyncImage.swift
//  Brick Collector
//
//  Created by Doug Salvati on 1/24/21.
//

import SwiftUI

struct AsyncImage: View {
    @StateObject private var loader: ImageLoader
    
    init(url: URL) {
        _loader = StateObject(wrappedValue: ImageLoader(url: url))
    }
    
    var body: some View {
        content
            .onAppear(perform: loader.load)
    }
    
    private var content: some View {
        Group {
            if loader.image != nil {
                Image(nsImage: loader.image!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
        }
    }
}
