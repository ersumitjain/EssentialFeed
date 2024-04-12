//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Sumit on 10/04/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader {
   private let client: HTTPClient
   private let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
   public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let .success(data, response) :
                completion(RemoteFeedLoader.map(data, response))
            case .failure:
                completion(.failure(.connectivity))
            }
            
        }
    }
    
    private static func map(_ data: Data, _ response: HTTPURLResponse) -> Result {
        do {
                       let items = try FeedItemsMapper.map(data, response)
                       return .success(items)
                       } catch { return .failure(.invalidData)
                       }
    }
}
