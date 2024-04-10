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
        
        sut.load { _ in}
        
        XCTAssertFalse(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestdataFromGivenURL() {
        let url = URL(string: "https://a-given-url.com")!
        
        let (sut, client) =  makeSut(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestdataFromGivenURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        
        let (sut, client) =  makeSut(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
         let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSut(url: url)
        
        var captureErrors = [RemoteFeedLoader.Error]()
        
        sut.load { captureErrors.append($0) }
        
        let clientErrors = NSError(domain: "Test", code: 0)
        client.complete(with: clientErrors)
        
        XCTAssertEqual(captureErrors, [.connectivity])
    }
    
    func test_load_deliversErrorOn400HTTPResponse() {
         let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSut(url: url)
        
        var captureErrors = [RemoteFeedLoader.Error]()
        
        sut.load { captureErrors.append($0) }
        
        
        client.complete(withStatuscode: 400)
        
        XCTAssertEqual(captureErrors, [.invalidData])
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
         let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSut(url: url)
        
        [199, 201, 300, 400, 500].enumerated().forEach { index, code in
        var captureErrors = [RemoteFeedLoader.Error]()
        
        sut.load { captureErrors.append($0) }
        
            client.complete(withStatuscode: code, at: index)
            
            XCTAssertEqual(captureErrors, [.invalidData])
            
        }
    }
    
    // Mark: - Helper
    
    private func makeSut(url: URL) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (Error?, HTTPURLResponse?) -> Void)]()
        
        var requestedURLs: [URL] {
            return messages.map {$0.url}
        }
        
        
        func get(from url: URL, completion: @escaping (Error?, HTTPURLResponse?) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(error, nil)
        }
        
        func complete(withStatuscode code: Int, at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index], statusCode: code, httpVersion: nil, headerFields: nil)
            messages[index].completion(nil, response)
        }
    }
}
