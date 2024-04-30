//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Sumit on 01/05/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import Foundation

func anyURL() -> URL {
    URL(string: "http://any-url.com")!
}

func anyError() -> NSError {
    return NSError(domain: "any error", code: 1)
}
