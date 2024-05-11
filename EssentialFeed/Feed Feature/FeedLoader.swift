//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Sumit on 09/04/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import Foundation

//public enum LoadFeedResult {
//    case success([FeedItem])
//    case failure(Error)
//}

public typealias LoadFeedResult = Result<[FeedItem], Error>

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
