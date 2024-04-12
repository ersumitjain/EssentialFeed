//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Sumit on 13/04/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import Foundation

final class FeedItemsMapper {
    private struct Root: Decodable {
        let items: [Item]
        
        var feed: [FeedItem] {
            items.map { $0.item }
        }
    }
    
    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL
        
        var item: FeedItem {
            return FeedItem(
                id: id,
                description: description,
                location: location,
                imageUrl: image)
        }
    }
    
    
    static func map(_ data: Data, _ response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        
        guard response.statusCode == 200,
        let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(.invalidData)
        }
        return .success(root.feed)
    }
}
