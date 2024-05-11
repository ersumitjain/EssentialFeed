//
//  EssentialFeedAPIEndToEndTests.swift
//  EssentialFeedTests
//
//  Created by Sumit on 16/04/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import XCTest
import EssentialFeed

class EssentialFeedAPIEndToEndTests: XCTestCase {
    
//    func demo() {
//        let cache = URLCache(memoryCapacity: 10*1024*1024, diskCapacity: 100*1024*1024, diskPath: nil)
//
//        let configuration = URLSessionConfiguration.default
//        configuration.urlCache = cache
//        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
//
//        let session = URLSession(configuration: configuration)
//
//        let url = URL(string: "http:// any-url.com")
//        let request = URLRequest(url: url, cachePolicy: .returnCacheDataDontLoad, timeoutInterval: 30)
//
//        URLCache.shared = cache
//    }
    
    func test_endToEndTestServerGETFeedResult_matchesFixedTestsAccountData() {
        
        let receivedResult = getFeedResult()
        switch receivedResult {
        case let .success(items):
            XCTAssertEqual(items.count, 8, "Expected 8 items in the test account feed")
            
            items.enumerated().forEach { (index, item) in
                XCTAssertEqual(item, expectedItem(at: index), "Unexpected item values at index \(index)")
            }
        case let .failure(error):
            XCTFail("Expected succesful feed result, got \(error) instead")
        default:
            XCTFail("Expected succesful feed result, got no result instead")
        }
    }
    
    //Mark: - Helper
    
    private func getFeedResult() -> FeedLoader.Result? {
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
//        let client = URLSessionHTTPClient()
        let client = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        
        let sut = RemoteFeedLoader(client: client, url: testServerURL)
        
        trackForMemoryLeaks(client)
        trackForMemoryLeaks(sut)
        
        var receivedResult: FeedLoader.Result?
        
        let exp = expectation(description: "wait for completion")
        
        sut.load { result in
            receivedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 5.0)
        
        return receivedResult
    }
    
    private func expectedItem(at index: Int) -> FeedItem {
        return FeedItem(
            id: id(at: index),
            description: description(at: index),
            location: location(at: index),
            imageUrl: imageUrl(at: index)
        )
    }
    
    private func id(at index: Int) -> UUID {
        return UUID(uuidString: [
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "BA298A85-6275-48D3-8315-9C8F7C1CD109",
            "5A0D45B3-8E26-4385-8C5D-213E160A5E3C",
            "FF0ECFE2-2879-403F-8DBE-A83B4010B340",
            "DC97EF5E-2CC9-4905-A8AD-3C351C311001",
            "557D87F1-25D3-4D77-82E9-364B2ED9CB30",
            "A83284EF-C2DF-415D-AB73-2A9B8B04950B",
            "F79BD7F8-063F-46E2-8147-A67635C3BB01",
            ][index])!
    }
    
    private func description(at index: Int) -> String? {
        return ([
            "Description 1",
            nil,
            "Description 3",
            nil,
            "Description 5",
            "Description 6",
            "Description 7",
            "Description 8",
            ][index])
    }
    
    private func location(at index: Int) -> String? {
        return ([
            "Location 1",
            "Location 2",
            nil,
            nil,
            "Location 5",
            "Location 6",
            "Location 7",
            "Location 8",
            ][index])
    }
    
    private func imageUrl(at index: Int) -> URL {
        return URL(string: [
            "https://url-1.com",
            "https://url-2.com",
            "https://url-3.com",
            "https://url-4.com",
            "https://url-5.com",
            "https://url-6.com",
            "https://url-7.com",
            "https://url-8.com",
            ][index])!
    }
}
