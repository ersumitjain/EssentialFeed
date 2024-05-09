//
//  CodableFeedStore.swift
//  EssentialFeed
//
//  Created by Sumit on 09/05/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import Foundation

public class CodableFeedStore: FeedStore {
    
    private struct Cache: Codable {
        let feeds: [CodableFeedItem]
        let timestamp: Date
        
        var localFeeds: [LocalFeedItem] {
            return feeds.map { $0.local }
        }
    }
    
    private struct CodableFeedItem: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let imageUrl: URL
        
        init(feed: LocalFeedItem) {
            id = feed.id
            description = feed.description
            location = feed.location
            imageUrl = feed.imageUrl
        }
        
        var local: LocalFeedItem {
            return LocalFeedItem(id: id, description: description, location: location, imageUrl: imageUrl)
        }
    }
    
    private let queue = DispatchQueue(label: "\(CodableFeedStore.self)Queue", qos: .userInitiated, attributes: .concurrent)
    private let storeURL: URL
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        let storeURL = self.storeURL
        queue.async {
            guard let data = try? Data(contentsOf: storeURL) else {
                return completion(.empty)
            }
            
            do {
                let decoder = JSONDecoder()
                let cache = try decoder.decode(Cache.self, from: data)
                completion(.found(feed: cache.localFeeds, timestamp: cache.timestamp))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func insert(items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
        let storeURL = self.storeURL
        queue.async {
            do {
                let encoder = JSONEncoder()
                let cache = Cache(feeds: items.map(CodableFeedItem.init), timestamp: timestamp)
                let encoded = try encoder.encode(cache)
                try encoded.write(to: storeURL)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func deleteCacheFeed(completion: @escaping DeletionCompletion) {
        let storeURL = self.storeURL
        queue.async {
            guard FileManager.default.fileExists(atPath: storeURL.path) else {
                return completion(nil)
            }
            
            do {
                try FileManager.default.removeItem(at: storeURL)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}
