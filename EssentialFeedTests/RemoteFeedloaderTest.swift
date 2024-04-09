//
//  RemoteFeedloaderTest.swift
//  EssentialFeedTests
//
//  Created by Sumit on 09/04/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import XCTest

class RemoteFeedLoader {
    
}

class HttpClient {
    var requestedURL: URL?
}

class RemoteFeedloaderTest: XCTestCase {

    func test_init_doesNotRequestDataFromUrl() {
        _ = RemoteFeedLoader()
        let client = HttpClient()
        
        XCTAssertNil(client.requestedURL)
    }
}
