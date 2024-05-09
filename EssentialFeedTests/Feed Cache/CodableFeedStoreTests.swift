//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Sumit on 04/05/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

/*
 Insert
 - To empty cache works
 - To non-empty cache overrides previous value
 - Error (if possible to simulate, e.g., no write permission)
 
 - Retrieve
 - Empty cache works (before something is inserted)
 - Empty cache twice works (before something is inserted)
 - Non-empty cache returns data
 - Non-empty cache twice returns same data (retrieve should have no side-effects)
 - Error (if possible to simulate, e.g., invalid data)
 
 - Delete
 - Empty cache does nothing (cache stays empty and does not fail)
 - Inserted data leaves cache empty
 - Error (if possible to simulate, e.g., no write permission)
 
 - Side-effects must run serially to avoid race-conditions (deleting the wrong cache... overriding the latest data...)
 */


import XCTest
import EssentialFeed

typealias FailableFeedStore = FailableRetrieveFeedStoreSpecs & FailableInsertFeedStoreSpecs

class CodableFeedStoreTests: XCTestCase, FailableFeedStore {
    
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toRetrieveTwice: .empty)
    }
    
    func test_retrieve_deliversFoundValueOnNonEmptyCache() {
        let sut = makeSUT()
        let feeds = uniqueItems().local
        let timestamp = Date()
        
        insert((feeds, timestamp), to: sut)
        
        expect(sut, toRetrieve: .found(feed: feeds, timestamp: timestamp))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let feeds = uniqueItems().local
        let timestamp = Date()
        
        insert((feeds, timestamp), to: sut)
        
        expect(sut, toRetrieveTwice: .found(feed: feeds, timestamp: timestamp))
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieve: .failure(anyError()))
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieveTwice: .failure(anyError()))
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        
        let firstInsertionError = insert((uniqueItems().local, Date()), to: sut)
        XCTAssertNil(firstInsertionError, "Expected to insert cache successfully")
        
        let latestFeed = uniqueItems().local
        let latestTimestamp = Date()
        let latestInsertionError = insert((latestFeed, latestTimestamp), to: sut)
        
        XCTAssertNil(latestInsertionError, "Expected to override cache successfully")
        
        expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
        
    }
    
    func test_insert_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueItems().local
        let timestamp = Date()
        
        let insertError = insert((feed, timestamp), to: sut)
        
        XCTAssertNotNil(insertError, "Expected cache insertion to fail with an error")
    }
    
    func test_insert_hasNoSideEffectOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueItems().local
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        insert((uniqueItems().local, Date()), to: sut)
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
        expect(sut, toRetrieve: .empty)
    }
    
//    func test_delete_deleiversErrorOnDeletionError() {
//        let noDeletePermissionURL = cachesDirectory()
//        let sut = makeSUT(storeURL: noDeletePermissionURL)
//
//        let deletionError = deleteCache(from: sut)
//
//        XCTAssertNil(deletionError, "Expected cache deletion to fail")
//        expect(sut, toRetrieve: .empty)
//    }
    
    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
        var completedOperation = [XCTestExpectation]()
        let opt1 = expectation(description: "Operation 1")
        sut.insert(items: uniqueItems().local, timestamp: Date()) { _ in
            completedOperation.append(opt1)
            opt1.fulfill()
        }
        
        let opt2 = expectation(description: "Operation 2")
        sut.deleteCacheFeed { _ in
            completedOperation.append(opt2)
            opt2.fulfill()
        }
        
        let opt3 = expectation(description: "Operation 3")
        sut.insert(items:uniqueItems().local, timestamp: Date()) { _ in
            completedOperation.append(opt3)
            opt3.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(completedOperation, [opt1, opt2, opt3], "Expected side-effects to run serially but operations finished in the wrong order")
    }
    
    
    // - Mark: Helpers
    
    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    private func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
}
