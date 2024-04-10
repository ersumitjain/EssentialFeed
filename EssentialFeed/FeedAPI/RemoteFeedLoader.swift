//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Sumit on 10/04/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

public final class RemoteFeedLoader {
   private let client: HTTPClient
   private let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
   public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Error) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .success:
                completion(.invalidData)
            case .failure:
                completion(.connectivity)
            }
            
        }
    }
}
