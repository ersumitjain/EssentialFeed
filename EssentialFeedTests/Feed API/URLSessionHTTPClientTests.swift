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
      //  let url = URL(string: "http://wrong-url.com")!
        session.dataTask(with: url) { (_, _, error) in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    func test_getFromURL_performGetRequestWithURL() {
        URLProtocolStub.startInterceptingRequests()
        let url = URL(string: "http://any-url.com")!
        
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        let sut = URLSessionHTTPClient()
        sut.get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_failsOnRequestError() {
        URLProtocolStub.startInterceptingRequests()
        let url = URL(string: "http://any-url.com")!
        
        let error = NSError(domain: "any error", code: 1)
        
        URLProtocolStub.stub(data: nil, response: nil, error: error)
        
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
        URLProtocolStub.stopInterceptingRequests()
    }

}

//extension URLSessionHTTPClientTests: CustomDebugStringConvertible {
//    public override var description: String {
//        return ""
//    }
//}

private class URLProtocolStub: URLProtocol {
    
    private static var stub: Stub?
    
    private static var requestObserver: ((URLRequest) -> Void)?
    
    private struct Stub {
        let data: Data?
        let response: HTTPURLResponse?
        let error: Error?
    }
    
    static func stub(data: Data?, response: HTTPURLResponse?, error: Error?) {
        URLProtocolStub.stub = Stub(data: data, response: response, error: error)
    }
    
    static func startInterceptingRequests() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }
    
    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        stub = nil
        requestObserver = nil
    }
    
    static func observeRequest(observer: @escaping(URLRequest)-> Void) {
        requestObserver = observer
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        requestObserver?(request)
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let data = URLProtocolStub.stub?.data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        if let response = URLProtocolStub.stub?.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        if let error = URLProtocolStub.stub?.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() { }
}