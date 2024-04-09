//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Sumit on 10/04/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL)
}

public final class RemoteFeedLoader {
   private let client: HTTPClient
   private let url: URL
    
   public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
   public func load() {
        client.get(from: url)
    }
}
