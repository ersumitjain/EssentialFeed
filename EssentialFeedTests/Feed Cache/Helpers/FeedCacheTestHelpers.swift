//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Sumit on 01/05/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import Foundation
import EssentialFeed

func uniqueItem() -> FeedItem {
    FeedItem(id: UUID(), description: nil, location: nil, imageUrl: anyURL())
}

func uniqueItems() -> (models: [FeedItem], local: [LocalFeedItem]) {
    let models = [uniqueItem(), uniqueItem()]
    
    let local = models.map { LocalFeedItem(id: $0.id, description: $0.description, location: $0.location, imageUrl: $0.imageUrl) }
    return (models, local)
}

extension Date {
    
    func minusFeedCacheMaxAge() -> Date {
       return adding(days: -7)
    }
    
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
