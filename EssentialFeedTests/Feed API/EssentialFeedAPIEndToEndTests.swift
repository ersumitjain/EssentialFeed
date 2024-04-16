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

    func test_endToEndTestServerGETFeedResult_matchesFixedTestsAccountData() {
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient()
        
        let sut = RemoteFeedLoader(client: client, url: testServerURL)
        
        var receivedResult: LoadFeedResult?
        
        let exp = expectation(description: "wait for completion")
        
        sut.load { result in
            receivedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 5.0)
        
        
        switch receivedResult {
        case let .success(items):
            XCTAssertEqual(items.count, 8, "Expected 8 items in the test account feed")
        case let .failure(error):
             XCTFail("Expected succesful feed result, got \(error) instead")
        default:
             XCTFail("Expected succesful feed result, got no result instead")
        }
    }
}
