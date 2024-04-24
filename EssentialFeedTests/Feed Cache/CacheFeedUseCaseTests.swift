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
        let (store, _) = makeSut()
        XCTAssertEqual(store.deleteChacheFeedCallCount, 0)
    }
    
    func test_save_requestsCacheDelete() {
        let (store, sut) = makeSut()
        
        let items = [uniqueItem(), uniqueItem()]
        sut.save(items: items)
        
         XCTAssertEqual(store.deleteChacheFeedCallCount, 1)
    }
    
    // Mark: - Helpers
    
    private func makeSut() -> (store: FeedStore, sut: LocalFeedLoader) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        
        return (store: store, sut: sut)
    }
    
    private func uniqueItem() -> FeedItem {
        FeedItem(id: UUID(), description: nil, location: nil, imageUrl: anyURL())
    }
    
    private func anyURL() -> URL {
        URL(string: "http://any-url.com")!
    }
}
