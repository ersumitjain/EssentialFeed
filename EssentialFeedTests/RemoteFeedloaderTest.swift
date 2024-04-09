//
//  RemoteFeedloaderTest.swift
//  EssentialFeedTests
//
//  Created by Sumit on 09/04/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import XCTest

class RemoteFeedLoader {
    func load() {
        HttpClient.shared.requestedURL = URL(string: "https://a-url.com")
    }
}

class HttpClient {
    static let shared = HttpClient()
    
    private init() {}
    
    var requestedURL: URL?
}

class RemoteFeedloaderTest: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        _ = RemoteFeedLoader()
        let client = HttpClient.shared
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestdataFromURL() {
        let sut = RemoteFeedLoader()
        let client = HttpClient.shared
        
        sut.load()
        
        XCTAssertNotNil(client.requestedURL)
    }
}
