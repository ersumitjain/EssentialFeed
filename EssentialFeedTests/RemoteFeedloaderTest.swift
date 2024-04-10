//
//  RemoteFeedloaderTest.swift
//  EssentialFeedTests
//
//  Created by Sumit on 09/04/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import XCTest
import EssentialFeed

class RemoteFeedloaderTest: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let url = URL(string: "https://a-url.com")!
       let (_, client) =  makeSut(url: url)
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestdataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        
        let (sut, client) =  makeSut(url: url)
        
        sut.load()
        
        XCTAssertFalse(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestdataFromGivenURL() {
        let url = URL(string: "https://a-given-url.com")!
        
        let (sut, client) =  makeSut(url: url)
        
        sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestdataFromGivenURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        
        let (sut, client) =  makeSut(url: url)
        
        sut.load()
        sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliverserrorOnClientError() {
         let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSut(url: url)
        
        var captureError = [RemoteFeedLoader.Error]()
        
        sut.load { captureError.append($0) }
        
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)
        
        XCTAssertEqual(captureError, [.connectivity])
    }
    
    // Mark: - Helper
    
    private func makeSut(url: URL) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURLs = [URL]()
        var completions = [(Error) -> Void]()
        
        func get(from url: URL, completion: @escaping (Error) -> Void) {
            completions.append(completion)
            requestedURLs.append(url)
        }
        
        func complete(with error: Error, at index: Int = 0) {
            self.completions[index](error)
        }
    }
}
