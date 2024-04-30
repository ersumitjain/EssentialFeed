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
    
    func test_load_deliversCacheImagesOnLessThanSevenDaysOldCache() {
        let items = uniqueItems()
        let fixedDate = Date()
        let lessThanSevenDaysOldTimeStamp = fixedDate.adding(days: -7).adding(seconds: 1)
        
        let (store, sut) = makeSut(currentDate: { fixedDate })
        
        expect(sut, toCompleteWith: .success(items.models)) {
            store.completeRetrieval(with: items.local, timestamp: lessThanSevenDaysOldTimeStamp)
        }
    }
    
    func test_load_deliversNoImagesOnSevenDaysOldCache() {
        let items = uniqueItems()
        let fixedDate = Date()
        let sevenDaysOldTimeStamp = fixedDate.adding(days: -7)
        
        let (store, sut) = makeSut(currentDate: { fixedDate })
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: items.local, timestamp: sevenDaysOldTimeStamp)
        }
    }
    
    func test_load_deliversNoImagesOnMoreThanSevenDaysOldCache() {
        let items = uniqueItems()
        let fixedDate = Date()
        let moreThanSevenDaysOldTimeStamp = fixedDate.adding(days: -7).adding(seconds: -1)
        
        let (store, sut) = makeSut(currentDate: { fixedDate })
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: items.local, timestamp: moreThanSevenDaysOldTimeStamp)
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
    
    func test_load_doesNotDeletesCacheOnLessThanSevenDaysOldCache() {
        let items = uniqueItems()
        let fixedDate = Date()
        let lessThanSevenDaysOldTimeStamp = fixedDate.adding(days: -7).adding(seconds: 1)
        
        let (store, sut) = makeSut(currentDate: { fixedDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: items.local, timestamp: lessThanSevenDaysOldTimeStamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }
    
    func test_load_deletesCacheOnSevenDaysOldCache() {
        let items = uniqueItems()
        let fixedDate = Date()
        let sevenDaysOldTimeStamp = fixedDate.adding(days: -7)
        
        let (store, sut) = makeSut(currentDate: { fixedDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: items.local, timestamp: sevenDaysOldTimeStamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrieve, .deleteCacheFeed])
    }
    
    func test_load_deletesCacheOnMoreThanSevenDaysOldCache() {
        let items = uniqueItems()
        let fixedDate = Date()
        let moreThanSevenDaysOldTimeStamp = fixedDate.adding(days: -7).adding(seconds: -1)
        
        let (store, sut) = makeSut(currentDate: { fixedDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: items.local, timestamp: moreThanSevenDaysOldTimeStamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrieve, .deleteCacheFeed])
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
    
    private func anyError() -> NSError {
        return NSError(domain: "any error", code: 1)
    }
    
    private func uniqueItem() -> FeedItem {
        FeedItem(id: UUID(), description: nil, location: nil, imageUrl: anyURL())
    }
    
    private func uniqueItems() -> (models: [FeedItem], local: [LocalFeedItem]) {
        let models = [uniqueItem(), uniqueItem()]
        
        let local = models.map { LocalFeedItem(id: $0.id, description: $0.description, location: $0.location, imageUrl: $0.imageUrl) }
        return (models, local)
    }
    
    private func anyURL() -> URL {
        URL(string: "http://any-url.com")!
    }
}

private extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
