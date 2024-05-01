//
//  ValidateFeedCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Sumit on 01/05/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import XCTest
import EssentialFeed

class ValidateFeedCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
           let (store, _) = makeSut()
           XCTAssertEqual(store.receivedMessage, [])
       }
    
    func test_validateCache_deletesCahceOnRetrievalError() {
        let (store, sut) = makeSut()
        
        sut.validateCache()
        store.completeRetrieval(with: anyError())
        
        XCTAssertEqual(store.receivedMessage, [.retrieve, .deleteCacheFeed])
    }
    
    func test_validateCache_doesNotDeletesCacheOnEmptyCache() {
        let (store, sut) = makeSut()
        
        sut.validateCache()
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }
    
    func test_validateCache_doesNotDeletesCacheOnNonExpiredCache() {
        let items = uniqueItems()
        let fixedDate = Date()
        let nonExpiredCache = fixedDate.minusFeedCacheMaxAge().adding(seconds: 1)
        
        let (store, sut) = makeSut(currentDate: { fixedDate })
        
        sut.validateCache()
        store.completeRetrieval(with: items.local, timestamp: nonExpiredCache)
        
        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }
    
    func test_validateCache_deletesCacheOnCacheExpiration() {
        let items = uniqueItems()
        let fixedDate = Date()
        let expirationTimeStamp = fixedDate.minusFeedCacheMaxAge()
        
        let (store, sut) = makeSut(currentDate: { fixedDate })
        
        sut.validateCache()
        store.completeRetrieval(with: items.local, timestamp: expirationTimeStamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrieve, .deleteCacheFeed])
    }
    
    func test_validateCache_deletesCacheOnExpiredCache() {
        let items = uniqueItems()
        let fixedDate = Date()
        let expiredCacheTimeStamp = fixedDate.minusFeedCacheMaxAge().adding(seconds: -1)
        
        let (store, sut) = makeSut(currentDate: { fixedDate })
        
        sut.validateCache()
        store.completeRetrieval(with: items.local, timestamp: expiredCacheTimeStamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrieve, .deleteCacheFeed])
    }
    
    func test_validateCache_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        sut?.validateCache()
        
        sut = nil
        store.completeRetrieval(with: anyError())
        
        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }
    
    // Mark: - Helpers
    
    private func makeSut(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (store: FeedStoreSpy, sut: LocalFeedLoader) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (store: store, sut: sut)
    }
    
}
