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
        HttPClient.shared.get(from: URL(string: "https://a-url.com")!)
    }
}

class HttPClient {
    static var shared = HttPClient()
    
    func get(from url: URL) {}
}

class HTTPClientSpy: HttPClient {
    var requestedURL: URL?
    
   override func get(from url: URL) {
        requestedURL = url
    }
}

class RemoteFeedloaderTest: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        _ = RemoteFeedLoader()
        let client = HTTPClientSpy()
        HttPClient.shared = client
        
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestdataFromURL() {
        let sut = RemoteFeedLoader()
        let client = HTTPClientSpy()
        HttPClient.shared = client
        
        sut.load()
        
        XCTAssertNotNil(client.requestedURL)
    }
}
