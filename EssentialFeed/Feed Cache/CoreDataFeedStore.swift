//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Sumit on 10/05/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import Foundation

public final class CoreDataFeedStore: FeedStore {
    
    public init() {}
    
    public func deleteCacheFeed(completion: @escaping DeletionCompletion) {
        
    }
    public func insert(items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
        
    }
    public func retrieve(completion: @escaping RetrievalCompletion) {
         completion(.empty)
    }
}
