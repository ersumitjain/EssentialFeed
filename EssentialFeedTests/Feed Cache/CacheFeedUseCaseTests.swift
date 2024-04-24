//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Sumit on 24/04/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import XCTest
import EssentialFeed

class LocalFeedLoader {
    let store: FeedStore
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(items: [FeedItem]) {
        store.deleteCacheFeed()
    }
}

class FeedStore {
    var deleteChacheFeedCallCount = 0
    
    func deleteCacheFeed() {
        deleteChacheFeedCallCount += 1
    }
}

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let store = FeedStore()
        let _ = LocalFeedLoader(store: store)
        
        XCTAssertEqual(store.deleteChacheFeedCallCount, 0)
    }
    
    func test_save_requestsCacheDelete() {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        let items = [FeedItem(id: UUID(), description: nil, location: nil, imageUrl: URL(string: "http://any-url.com")!)]
        
        sut.save(items: items)
        
         XCTAssertEqual(store.deleteChacheFeedCallCount, 1)
    }
    
}
