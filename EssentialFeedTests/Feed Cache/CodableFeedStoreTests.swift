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
        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFoundValueOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        assertThatRetrieveDeliversFailureOnRetrievalError(on: sut, storeURL: storeURL)
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        assertThatRetrieveHasNoSideEffectsOnFailure(on: sut, storeURL: storeURL)
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        
        assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        
        assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }
    
    func test_insert_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        
        let sut = makeSUT(storeURL: invalidStoreURL)
        
        assertThatInsertDeliversErrorOnInsertionError(on: sut)
    }
    
    func test_insert_hasNoSideEffectOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        
        let sut = makeSUT(storeURL: invalidStoreURL)
        assertThatInsertHasNoSideEffectOnInsertionError(on: sut)
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
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
