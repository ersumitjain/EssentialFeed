//
//  XCTestCases+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Sumit on 10/05/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    
    func assertThatRetrieveDeliversEmptyOnEmptyCache(on sut: FeedStore) {
        expect(sut, toRetrieve: .empty)
    }
    
    func assertThatRetrieveHasNoSideEffectsOnEmptyCache(on sut: FeedStore) {
        expect(sut, toRetrieveTwice: .empty)
    }
    
    func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on sut: FeedStore) {
        let feeds = uniqueItems().local
        let timestamp = Date()
        
        insert((feeds, timestamp), to: sut)
        
        expect(sut, toRetrieve: .found(feed: feeds, timestamp: timestamp))
    }
    
    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on sut: FeedStore) {
         let feeds = uniqueItems().local
               let timestamp = Date()
               
               insert((feeds, timestamp), to: sut)
               
               expect(sut, toRetrieveTwice: .found(feed: feeds, timestamp: timestamp))
    }
    
    func assertThatRetrieveDeliversFailureOnRetrievalError(on sut: FeedStore, storeURL: URL) {
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieve: .failure(anyError()))
    }
    
    func assertThatRetrieveHasNoSideEffectsOnFailure(on sut: FeedStore, storeURL: URL) {
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieveTwice: .failure(anyError()))
    }
    
    func assertThatInsertDeliversNoErrorOnEmptyCache(on sut: FeedStore) {
        let insertionError = insert((uniqueItems().local, Date()), to: sut)
        
        XCTAssertNil(insertionError, "Expected to insert cache successfully")
    }
    
    func assertThatInsertOverridesPreviouslyInsertedCacheValues(on sut: FeedStore) {
        let firstInsertionError = insert((uniqueItems().local, Date()), to: sut)
        XCTAssertNil(firstInsertionError, "Expected to insert cache successfully")
        
        let latestFeed = uniqueItems().local
        let latestTimestamp = Date()
        let latestInsertionError = insert((latestFeed, latestTimestamp), to: sut)
        
        XCTAssertNil(latestInsertionError, "Expected to override cache successfully")
        
        expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
    }
    
    func assertThatInsertDeliversErrorOnInsertionError(on sut: FeedStore) {
        let feed = uniqueItems().local
        let timestamp = Date()
        
        let insertError = insert((feed, timestamp), to: sut)
        
        XCTAssertNotNil(insertError, "Expected cache insertion to fail with an error")
    }
    
    func assertThatInsertHasNoSideEffectOnInsertionError(on sut: FeedStore) {
        let feed = uniqueItems().local
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)
        
        expect(sut, toRetrieve: .empty)
    }
    
    func assertThatDeleteHasNoSideEffectsOnEmptyCache(on sut: FeedStore) {
           let deletionError = deleteCache(from: sut)
           
           XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
           expect(sut, toRetrieve: .empty)
       }
    
    func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: FeedStore) {
        insert((uniqueItems().local, Date()), to: sut)
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
        expect(sut, toRetrieve: .empty)
    }
    

    // Helper
   @discardableResult
    func insert(_ cache: (feed: [LocalFeedItem], timestamp: Date), to sut: FeedStore) -> Error? {
        let exp = expectation(description: "wait for cache insertion")
        var insertionError: Error?
        sut.insert(items: cache.feed, timestamp: cache.timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
    
    func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "wait for cache deletion")
        var deletionError: Error?
        sut.deleteCacheFeed { receivedDeletionError in
            deletionError = receivedDeletionError
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        return deletionError
    }
    
    func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrieveCacheFeedResult) {
        expect(sut, toRetrieve: expectedResult)
        expect(sut, toRetrieve: expectedResult)
    }
    
    func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveCacheFeedResult) {
        let exp = expectation(description: "wait for cache retieval")
        
        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.empty, .empty),
                 (.failure, .failure):
                break
                
            case let (.found(expected), .found(retrieved)):
                XCTAssertEqual(expected.feed, retrieved.feed)
                XCTAssertEqual(expected.timestamp, retrieved.timestamp)
                
            default:
                XCTFail("expected to retrieve \(expectedResult) result, got \(retrievedResult) instead")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}
