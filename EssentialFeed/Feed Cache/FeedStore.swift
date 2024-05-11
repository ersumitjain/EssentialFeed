//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Sumit on 25/04/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import Foundation

//1
//public enum RetrieveCacheFeedResult {
//    case empty
//    case found(feed: [LocalFeedItem], timestamp: Date)
//    case failure(Error)
//}

//2
//public enum RetrieveCacheFeedResult {
//   case success(CachedFeed)
//    case failure(Error)
//}

public typealias RetrieveCacheFeedResult = Result<CachedFeed, Error>

public enum CachedFeed {
    case empty
    case found(feed: [LocalFeedItem], timestamp: Date)
}

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (RetrieveCacheFeedResult) -> Void
    
    func deleteCacheFeed(completion: @escaping DeletionCompletion)
    func insert(items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
    func retrieve(completion: @escaping RetrievalCompletion)
}
