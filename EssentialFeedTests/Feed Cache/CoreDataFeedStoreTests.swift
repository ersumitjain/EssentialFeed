//
//  CoreDataFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Sumit on 10/05/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import XCTest
import EssentialFeed

class CoreDataFeedStore: FeedStore {
    func deleteCacheFeed(completion: @escaping DeletionCompletion) {
        
    }
    func insert(items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
        
    }
    func retrieve(completion: @escaping RetrievalCompletion) {
        completion(.empty)
    }
}

class CoreDataFeedStoreTests: XCTestCase, FailableFeedStore {
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
//        let sut = makeSUT()
//
//        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFoundValueOnNonEmptyCache() {
//        let sut = makeSUT()
//
//        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
//        let sut = makeSUT()
//
//        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() {
//        let storeURL = testSpecificStoreURL()
//        let sut = makeSUT(storeURL: storeURL)
//
//        assertThatRetrieveDeliversFailureOnRetrievalError(on: sut, storeURL: storeURL)
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure() {
//        let storeURL = testSpecificStoreURL()
//        let sut = makeSUT(storeURL: storeURL)
//
//        assertThatRetrieveHasNoSideEffectsOnFailure(on: sut, storeURL: storeURL)
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() {
//        let sut = makeSUT()
//
//        assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
//        let sut = makeSUT()
//
//        assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }
    
    func test_insert_deliversErrorOnInsertionError() {
//        let invalidStoreURL = URL(string: "invalid://store-url")!
//
//        let sut = makeSUT(storeURL: invalidStoreURL)
//
//        assertThatInsertDeliversErrorOnInsertionError(on: sut)
    }
    
    func test_insert_hasNoSideEffectOnInsertionError() {
//        let invalidStoreURL = URL(string: "invalid://store-url")!
//
//        let sut = makeSUT(storeURL: invalidStoreURL)
//        assertThatInsertHasNoSideEffectOnInsertionError(on: sut)
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
//        let sut = makeSUT()
//
//        assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
//        let sut = makeSUT()
//        assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }
    
    func test_storeSideEffects_runSerially() {
        
    }
    
    
    // - MARK: Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let sut = CoreDataFeedStore()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
