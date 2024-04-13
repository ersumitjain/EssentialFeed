//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Sumit on 14/04/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient: HTTPClient {
    let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { (_, _, error) in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    func test_getFromURL_failsOnRequestError() {
        URLProtocol.registerClass(URLProtocolStub.self)
        let url = URL(string: "http://any-url.com")!
        
        let error = NSError(domain: "any error", code: 1)
        
        URLProtocolStub.stub(url: url, data: nil, response: nil, error: error)
        
        let sut = URLSessionHTTPClient()
        
        let exp = expectation(description: "wait for completion")
        
        sut.get(from: url) { result in
            switch result {
            case let .failure(receiverError as NSError):
                XCTAssertEqual(receiverError, error)
            default:
                XCTFail("Expectation failure with error \(error), got \(result) instead")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        URLProtocol.unregisterClass(URLProtocolStub.self)
    }

}

private class URLProtocolStub: URLProtocol {
    
    private static var stubs = [URL: Stub]()
    
    private struct Stub {
        let data: Data?
        let response: HTTPURLResponse?
        let error: Error?
    }
    
    static func stub(url: URL, data: Data?, response: HTTPURLResponse?, error: Error?) {
        stubs[url] = Stub(data: data, response: response, error: error)
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        return URLProtocolStub.stubs[url] != nil
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url, let stub = URLProtocolStub.stubs[url] else {
            return
        }
        
        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        if let response = stub.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() { }
}
