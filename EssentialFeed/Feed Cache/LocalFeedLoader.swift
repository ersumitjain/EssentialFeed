//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Sumit on 25/04/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
   public  init(store: FeedStore, currentDate: @escaping() -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
  public func save(items: [FeedItem], completion: @escaping(Error?) -> Void) {
        store.deleteCacheFeed { [weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.chach(items, completion: completion)
            }
        }
    }
    
    public func load(completion: @escaping(Error?) -> Void) {
        store.retrieve(completion: completion)
    }
    
    private func chach(_ items: [FeedItem], completion: @escaping(Error?) -> Void) {
        store.insert(items: items.toLocal(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

private extension Array where Element == FeedItem {
    func toLocal() -> [LocalFeedItem] {
        return map { LocalFeedItem(
            id: $0.id,
            description: $0.description,
            location: $0.location,
            imageUrl: $0.imageUrl)
        }
    }
}
