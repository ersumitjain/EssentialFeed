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


class CodableFeedStore {
    
    private struct Cache: Codable {
        let feeds: [CodableFeedItem]
        let timestamp: Date
        
        var localFeeds: [LocalFeedItem] {
            return feeds.map { $0.local }
        }
    }
    
    private struct CodableFeedItem: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let imageUrl: URL
        
        init(feed: LocalFeedItem) {
            id = feed.id
            description = feed.description
            location = feed.location
            imageUrl = feed.imageUrl
        }
        
        var local: LocalFeedItem {
            return LocalFeedItem(id: id, description: description, location: location, imageUrl: imageUrl)
        }
    }
    
    private let storeURL: URL
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        do {
        let decoder = JSONDecoder()
        let cache = try decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.localFeeds, timestamp: cache.timestamp))
        } catch {
            completion(.failure(error))
        }
    }
    
    func insert(items: [LocalFeedItem], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let cache = Cache(feeds: items.map(CodableFeedItem.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}

class CodableFeedStoreTests: XCTestCase {
    
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
        let sut = makeSUT()
        
        try! "invalid data".write(to: testSpecificStoreURL(), atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieve: .failure(anyError()))
    }
    
    
    // - Mark: Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func insert(_ cache: (feed: [LocalFeedItem], timestamp: Date), to sut: CodableFeedStore) {
        let exp = expectation(description: "wait for cache insertion")
        
        sut.insert(items: cache.feed, timestamp: cache.timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func expect(_ sut: CodableFeedStore, toRetrieveTwice expectedResult: RetrieveCacheFeedResult) {
        expect(sut, toRetrieve: expectedResult)
        expect(sut, toRetrieve: expectedResult)
    }
    
    private func expect(_ sut: CodableFeedStore, toRetrieve expectedResult: RetrieveCacheFeedResult) {
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
