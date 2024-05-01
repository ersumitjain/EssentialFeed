//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Sumit on 28/04/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (store, _) = makeSut()
        XCTAssertEqual(store.receivedMessage, [])
    }
    
    func test_load_requestsCacheRetrieval() {
        let (store, sut) = makeSut()
        
        sut.load { _ in }
        
        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }
    
    func test_load_failsOnRetrievalError() {
        let (store, sut) = makeSut()
        let retrievalError = anyError()
        
        expect(sut, toCompleteWith: .failure(retrievalError)) {
            store.completeRetrieval(with: retrievalError)
        }
    }
    
    func test_load_deliversNoImageOnEmptyCache() {
        let (store, sut) = makeSut()
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrievalWithEmptyCache()
        }
    }
    
    func test_load_deliversCacheImagesOnNonExpiredCache() {
        let items = uniqueItems()
        let fixedDate = Date()
        let nonExpiredTimeStamp = fixedDate.minusFeedCacheMaxAge().adding(seconds: 1)
        
        let (store, sut) = makeSut(currentDate: { fixedDate })
        
        expect(sut, toCompleteWith: .success(items.models)) {
            store.completeRetrieval(with: items.local, timestamp: nonExpiredTimeStamp)
        }
    }
    
    func test_load_deliversNoImagesOnCacheExpiration() {
        let items = uniqueItems()
        let fixedDate = Date()
        let expirationTimeStamp = fixedDate.minusFeedCacheMaxAge()
        
        let (store, sut) = makeSut(currentDate: { fixedDate })
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: items.local, timestamp: expirationTimeStamp)
        }
    }
    
    func test_load_deliversNoImagesOnExpiredCache() {
        let items = uniqueItems()
        let fixedDate = Date()
        let expiredTimeStamp = fixedDate.minusFeedCacheMaxAge().adding(seconds: -1)
        
        let (store, sut) = makeSut(currentDate: { fixedDate })
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: items.local, timestamp: expiredTimeStamp)
        }
    }
    
    func test_load_hasNoSideEffectsOnRetrievalError() {
        let (store, sut) = makeSut()
        
        sut.load { _ in }
        store.completeRetrieval(with: anyError())
        
        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnEmptyCache() {
        let (store, sut) = makeSut()
        
        sut.load { _ in }
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnNonExpiredCache() {
        let items = uniqueItems()
        let fixedDate = Date()
        let nonExpiredCacheTimeStamp = fixedDate.minusFeedCacheMaxAge().adding(seconds: 1)
        
        let (store, sut) = makeSut(currentDate: { fixedDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: items.local, timestamp: nonExpiredCacheTimeStamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnCacheExpiration() {
        let items = uniqueItems()
        let fixedDate = Date()
        let expirationTimeStamp = fixedDate.minusFeedCacheMaxAge()
        
        let (store, sut) = makeSut(currentDate: { fixedDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: items.local, timestamp: expirationTimeStamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnExpiredCache() {
        let items = uniqueItems()
        let fixedDate = Date()
        let expiredCacheTimeStamp = fixedDate.minusFeedCacheMaxAge().adding(seconds: -1)
        
        let (store, sut) = makeSut(currentDate: { fixedDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: items.local, timestamp: expiredCacheTimeStamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.LoadResult]()
        
        sut?.load{ receivedResults.append($0)}
        
        sut = nil
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    // Mark: - Helpers
    
    private func makeSut(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (store: FeedStoreSpy, sut: LocalFeedLoader) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (store: store, sut: sut)
    }
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.LoadResult, when action: () -> Void) {
        
        let exp = expectation(description: "wait for load completion")
        
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedImages), .success(expectedImages)):
                XCTAssertEqual(receivedImages, expectedImages)
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError)
            default:
                XCTFail("Expected result \(expectedResult), got \(receivedResult) instead")
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
    }
}
