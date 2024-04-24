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
        store.deleteCacheFeed { [unowned self] error in
            
            if error == nil {
                self.store.insert(items: items)
            }
        }
    }
}

class FeedStore {
    var deleteChacheFeedCallCount = 0
    var insertionCallCount = 0
    
    private var deletionCompletion = [(Error?) -> Void]()
    
    func deleteCacheFeed(completion: @escaping(Error?) -> Void) {
        deleteChacheFeedCallCount += 1
        deletionCompletion.append(completion)
    }
    
    func insert(items: [FeedItem]) {
        insertionCallCount += 1
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletion[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
         deletionCompletion[index](nil)
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
    
    func test_save_doesNotRequestsCacheInsertionOnDeletionError() {
        let (store, sut) = makeSut()
        let deletionError = anyError()
        
        let items = [uniqueItem(), uniqueItem()]
        sut.save(items: items)
        
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.insertionCallCount, 0)
    }
    
    func test_save_requestsCacheInsertionOnSuccessfullyDeletion() {
        let (store, sut) = makeSut()
        
        let items = [uniqueItem(), uniqueItem()]
        sut.save(items: items)
        
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.insertionCallCount, 1)
    }
    
    // Mark: - Helpers
    
    private func makeSut(file: StaticString = #file, line: UInt = #line) -> (store: FeedStore, sut: LocalFeedLoader) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (store: store, sut: sut)
    }
    
    private func uniqueItem() -> FeedItem {
        FeedItem(id: UUID(), description: nil, location: nil, imageUrl: anyURL())
    }
    
    private func anyURL() -> URL {
        URL(string: "http://any-url.com")!
    }
    
    private func anyError() -> Error {
        return NSError(domain: "any error", code: 1)
    }
}
