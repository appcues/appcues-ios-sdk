//
//  RemoteImage.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI
import Combine

// AsyncImage is iOS 15+, so borrow this from
// https://www.vadimbulavin.com/asynchronous-swiftui-image-loading-from-url-with-combine-and-swift/

internal class ImageLoader: ObservableObject {
    @Published var animatedImage: FLAnimatedImage?
    @Published var image: UIImage?
    private(set) var isLoading = false
    private let url: URL

    private var cache: SessionImageCache?

    private var cancellable: AnyCancellable?

    init(url: URL, cache: SessionImageCache? = nil) {
        self.url = url
        self.cache = cache
        if let animatedImage: FLAnimatedImage = cache?[url] {
            self.animatedImage = animatedImage
        } else if let image: UIImage = cache?[url] {
            self.image = image
        }
    }

    func load() {
        guard !isLoading else { return }

        if let animatedImage: FLAnimatedImage = cache?[url] {
            self.animatedImage = animatedImage
            return
        } else if let image: UIImage = cache?[url] {
            self.image = image
            return
        }

        self.isLoading = true
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            }, receiveValue: { [weak self, url] output in
                if output.data.isAnimatedImage {
                    self?.animatedImage = FLAnimatedImage(data: output.data)
                    self?.cache?[url] = self?.animatedImage
                } else {
                    self?.image = UIImage(data: output.data)
                    self?.cache?[url] = self?.image
                }
            })
    }

    func cancel() {
        cancellable?.cancel()
    }

    deinit {
        cancel()
    }
}

internal struct RemoteImage<Placeholder: View>: View {
    @ObservedObject private var loader: ImageLoader
    private let placeholder: Placeholder

    var body: some View {
        if let animatedImage = loader.animatedImage {
            AnimatedImage(animatedImage: animatedImage)
        } else if let image = loader.image {
            Image(uiImage: image)
                .resizable()
        } else {
            placeholder
                .onAppear(perform: loader.load)
        }
    }

    init(url: URL, cache: SessionImageCache, @ViewBuilder placeholder: () -> Placeholder) {
        self.placeholder = placeholder()
        loader = ImageLoader(url: url, cache: cache)
    }
}
