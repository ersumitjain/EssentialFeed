//
//  ManagedFeedImage.swift
//  EssentialFeed
//
//  Created by Sumit on 11/05/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import CoreData

@objc(ManagedFeedImage)
internal class ManagedFeedImage: NSManagedObject {
    @NSManaged internal var id: UUID
    @NSManaged internal var imageDescription: String?
    @NSManaged internal var location: String?
    @NSManaged internal var url: URL
    @NSManaged internal var cache: ManagedCache
}

extension ManagedFeedImage {
    
    internal static func images(from localFeed: [LocalFeedItem], in context: NSManagedObjectContext) -> NSOrderedSet {
        return NSOrderedSet(array: localFeed.map { local in
            let managed = ManagedFeedImage(context: context)
            managed.id = local.id
            managed.imageDescription = local.description
            managed.location = local.location
            managed.url = local.imageUrl
            return managed
        })
    }
    
    internal var local: LocalFeedItem {
        return LocalFeedItem(id: id, description: imageDescription, location: location, imageUrl: url)
    }
}
