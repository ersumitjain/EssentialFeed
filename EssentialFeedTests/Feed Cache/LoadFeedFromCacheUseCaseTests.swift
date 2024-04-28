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
    
    // Mark: - Helpers
    
    private func makeSut(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (store: FeedStoreSpy, sut: LocalFeedLoader) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (store: store, sut: sut)
    }
    
    private class FeedStoreSpy: FeedStore {
        enum ReceivedMessage: Equatable {
            case deleteCacheFeed
            case insert([LocalFeedItem], Date)
        }
        
        private(set) var receivedMessage = [ReceivedMessage]()
        private var deletionCompletion = [DeletionCompletion]()
        private var insertionCompletion = [InsertionCompletion]()
        
        func deleteCacheFeed(completion: @escaping DeletionCompletion) {
            deletionCompletion.append(completion)
            receivedMessage.append(.deleteCacheFeed)
        }
        
        func insert(items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
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
