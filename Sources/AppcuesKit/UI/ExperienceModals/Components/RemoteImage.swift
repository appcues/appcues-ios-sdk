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
    @Published var image: UIImage?
    private(set) var isLoading = false
    private let url: URL

    private var cache: SessionImageCache?

    private var cancellable: AnyCancellable?

    init(url: URL, cache: SessionImageCache? = nil) {
        self.url = url
        self.cache = cache
        self.image = cache?[url]
    }

    func load() {
        guard !isLoading else { return }

        if let image = cache?[url] {
            self.image = image
            return
        }

        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .handleEvents(receiveSubscription: { [weak self] _ in self?.isLoading = true },
                          receiveOutput: { [weak self, url] in self?.cache?[url] = $0 },
                          receiveCompletion: { [weak self] _ in self?.isLoading = false },
                          receiveCancel: { [weak self] in self?.isLoading = false })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.image = $0 }
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
        if let image = loader.image {
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
