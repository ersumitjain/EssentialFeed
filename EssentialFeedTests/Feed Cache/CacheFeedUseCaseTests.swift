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
    private let store: FeedStore
    private let currentDate: () -> Date
    init(store: FeedStore, currentDate: @escaping() -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(items: [FeedItem], completion: @escaping(Error?) -> Void) {
        store.deleteCacheFeed { [weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.store.insert(items: items, timestamp: self.currentDate()) { [weak self] error in
                    guard self != nil else { return }
                    completion(error)
                }
            }
        }
    }
}

protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCacheFeed(completion: @escaping DeletionCompletion)
    func insert(items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
    
}

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
        
        let items = [uniqueItem(), uniqueItem()]
        sut.save(items: items, completion: {_ in })
        
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessage, [.deleteCacheFeed, .insert(items, timestamp)])
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
    
    private func anyURL() -> URL {
        URL(string: "http://any-url.com")!
    }
    
    private func anyError() -> NSError {
        return NSError(domain: "any error", code: 1)
    }
    
    private class FeedStoreSpy: FeedStore {
        enum ReceivedMessage: Equatable {
            case deleteCacheFeed
            case insert([FeedItem], Date)
        }
        
        private(set) var receivedMessage = [ReceivedMessage]()
        private var deletionCompletion = [DeletionCompletion]()
        private var insertionCompletion = [InsertionCompletion]()
        
        func deleteCacheFeed(completion: @escaping DeletionCompletion) {
            deletionCompletion.append(completion)
            receivedMessage.append(.deleteCacheFeed)
        }
        
        func insert(items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
            insertionCompletion.append(completion)
            receivedMessage.append(.insert(items, timestamp))
        }
        
        func completeDeletion(with error: Error, at index: Int = 0) {
            deletionCompletion[index](error)
        }
        
        func completeDeletionSuccessfully(at index: Int = 0) {
            deletionCompletion[index](nil)
        }
        
        func completeInsertion(with error: Error, at index: Int = 0) {
            insertionCompletion[index](error)
        }
        
        func completeInsertionSuccessfully(at index: Int = 0) {
            insertionCompletion[index](nil)
        }
    }
}
