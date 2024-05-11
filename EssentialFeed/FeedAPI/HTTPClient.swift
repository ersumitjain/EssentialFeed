//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Sumit on 13/04/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import Foundation

//public enum HTTPClientResult {
//    case success(Data, HTTPURLResponse)
//    case failure(Error)
//}

//public typealias HTTPClientResult = Result<(Data, HTTPURLResponse), Error>

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    
    func get(from url: URL, completion: @escaping (Result) -> Void)
}
