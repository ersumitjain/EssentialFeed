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
        
        expect(sut, toCompleteWith: .failure(.connectivity), when: {
                  let clientErrors = NSError(domain: "Test", code: 0)
              client.complete(with: clientErrors)
        })
    }
    
    func test_load_deliversErrorOn400HTTPResponse() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSut(url: url)
        
        expect(sut, toCompleteWith: .failure(.invalidData), when:  {
             client.complete(withStatuscode: 400)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSut(url: url)
        
        [199, 201, 300, 400, 500].enumerated().forEach { index, code in
            
            expect(sut, toCompleteWith: .failure(.invalidData), when: {
                client.complete(withStatuscode: code, at: index)
            })
        }
    }
    
    func test_load_deliversErrorsOn200HTTPResponseWithInvalidJson() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSut(url: url)
        
        expect(sut, toCompleteWith: .failure(.invalidData), when: {
            let invalidJson = Data("Invalid json".utf8)
            client.complete(withStatuscode: 200, data: invalidJson)
        })
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJsonList() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSut(url: url)
      //  var capturedResult = [RemoteFeedLoader.Result]()
     //   sut.load { capturedResult.append($0) }
        expect(sut, toCompleteWith: .success([])) {
             let emptyListJson = Data(bytes: "{\"items\": []}".utf8)
                   client.complete(withStatuscode: 200, data: emptyListJson)
        }
    }
    
    func test_load_deliversItemsON200HTTPResponseWithJsonItems() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSut(url: url)
        
        let item1 =  makeItem(
            id: UUID(),
            imageURL: URL(string: "https://a-given-url.com")!)
        
        let item2 =  makeItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            imageURL: URL(string: "https://another-given-url.com")!)
        
        let items = [item1.model, item2.model]
        
        expect(sut, toCompleteWith: .success(items)) {
            let json = makeItemJSON([item1.json, item2.json])
            client.complete(withStatuscode: 200, data: json)
        }
    }
    
    // Mark: - Helper
    
    private func makeSut(url: URL) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        
        let sut = RemoteFeedLoader(client: client, url: url)
        
        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(client)
        
        return (sut, client)
    }
    
    private func trackForMemoryLeaks(_ instance: AnyObject) {
       addTeardownBlock { [weak instance] in
           XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.")
       }
       }
    
    private func makeItem(
        id: UUID,
        description: String? = nil,
        location: String? = nil,
        imageURL: URL) -> (model: FeedItem, json: [String: Any])
    {
        let item = FeedItem(id: id, description: description, location: location, imageUrl: imageURL)
        
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image":  imageURL.absoluteString
            ].compactMapValues { $0 }
        return (item, json)
    }
    
    private func makeItemJSON(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWith result: RemoteFeedLoader.Result, when action: () -> Void) {
        var capturedResults = [RemoteFeedLoader.Result]()
        
        sut.load { capturedResults.append($0) }
        
        action()
        
        XCTAssertEqual(capturedResults, [result])
    }
    
    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        var requestedURLs: [URL] {
            return messages.map {$0.url}
        }
        
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatuscode code: Int, data: Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index], statusCode: code, httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success(data, response))
        }
    }
}
