//
//  XCTestcase+MemoryLeakTracking.swift
//  EssentialFeedTests
//
//  Created by Sumit on 14/04/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import XCTest

extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}
