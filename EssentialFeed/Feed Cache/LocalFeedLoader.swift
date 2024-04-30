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
    private let calendar = Calendar(identifier: .gregorian)
    
    public typealias LoadResult = LoadFeedResult
    
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
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [unowned self] result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
                self.store.deleteCacheFeed { _ in }
            case let .found(feed, timestamp) where self.validate(timestamp):
                completion(.success(feed.toModels()))
            case .found, .emplty:
                completion(.success([]))
            }
        }
    }
    
    private var maxCacheAgeInDays: Int {
        return 7
    }
    
    private func validate(_ timestamp: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return currentDate() < maxCacheAge
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

private extension Array where Element == LocalFeedItem {
    func toModels() -> [FeedItem] {
        return map { FeedItem(id: $0.id, description: $0.description, location: $0.location, imageUrl: $0.imageUrl)
        }
    }
}
