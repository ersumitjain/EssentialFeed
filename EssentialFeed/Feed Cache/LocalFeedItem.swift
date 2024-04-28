//
//  LocalFeedItem.swift
//  EssentialFeed
//
//  Created by Sumit on 28/04/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import Foundation

public struct LocalFeedItem: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageUrl: URL
    
    public init(id: UUID, description: String?, location: String?, imageUrl: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.imageUrl = imageUrl
    }
}
