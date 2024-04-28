//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Sumit on 24/04/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import XCTest
import EssentialFeed

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotMessageStoreUponCreation() {
        let (store, _) = makeSut()
        XCTAssertEqual(store.receivedMessage, [])
    }
    
    func test_save_requestsCacheDelete() {
        let (store, sut) = makeSut()
        
        let items = [uniqueItem(), uniqueItem()]
        sut.save(items: items, completion: {_ in })
        
        XCTAssertEqual(store.receivedMessage, [.deleteCacheFeed])
    }
    
    func test_save_doesNotRequestsCacheInsertionOnDeletionError() {
        let (store, sut) = makeSut()
        let deletionError = anyError()
        
        let items = [uniqueItem(), uniqueItem()]
        sut.save(items: items, completion: {_ in })
        
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessage, [.deleteCacheFeed])
    }
    
    func test_save_requestsCacheInsertionWithTimestampOnSuccessfullyDeletion() {
        let timestamp = Date()
        
        let (store, sut) = makeSut(currentDate: { timestamp })
        
        let items = uniqueItems()
        
        sut.save(items: items.models, completion: {_ in })
        
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessage, [.deleteCacheFeed, .insert(items.local, timestamp)])
    }
    
    func test_save_failsOnDeletionError() {
        
        let (store, sut) = makeSut()
        let deletionError = anyError()
        
        expect(sut, toCompleteWithError: deletionError) {
            store.completeDeletion(with: deletionError)
        }
    }
    
    func test_save_failsOnInsertionError() {
        let (store, sut) = makeSut()
        let insertionError = anyError()
        
        expect(sut, toCompleteWithError: insertionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        }
    }
    
    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (store, sut) = makeSut()
        
        expect(sut, toCompleteWithError: nil) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }
    
    func test_save_doesNotdeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedError = [Error?]()
        sut?.save(items: [uniqueItem()]) { receivedError.append($0)}
        
        sut = nil
        store.completeDeletion(with: anyError())
        
        XCTAssertTrue(receivedError.isEmpty)
    }
    
    func test_save_doesNotdeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedError = [Error?]()
        sut?.save(items: [uniqueItem()]) { receivedError.append($0)}
        
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyError())
        
        XCTAssertTrue(receivedError.isEmpty)
    }
    
    // Mark: - Helpers
    
    private func makeSut(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (store: FeedStoreSpy, sut: LocalFeedLoader) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (store: store, sut: sut)
    }
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWithError expectedError: NSError?, when action: () -> Void) {
        let items = [uniqueItem(), uniqueItem()]
        let exp = expectation(description: "wait for completion")
        var receivedError: Error?
        sut.save(items: items) { error in
            receivedError = error
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, expectedError)
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
    
    private func anyError() -> NSError {
        return NSError(domain: "any error", code: 1)
    }
}
