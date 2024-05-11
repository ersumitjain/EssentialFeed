//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Sumit on 15/04/24.
//  Copyright © 2024 Sumit. All rights reserved.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    private struct UnexpectedValuesRepresentation: Error {}
    
    public func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        //  let url = URL(string: "http://wrong-url.com")!
        session.dataTask(with: url) { (data, response, error) in
            //            if let error = error {
            //                completion(.failure(error))
            //            } else if let data = data, let response = response as? HTTPURLResponse {
            //                completion(.success((data, response)))
            //            } else {
            //                completion(.failure(UnexpectedValuesRepresentation()))
            //            }
            completion(Result {
                if let error = error {
                    throw error
                } else if let data = data, let response = response as? HTTPURLResponse {
                   return (data, response)
                } else {
                    throw UnexpectedValuesRepresentation()
                }
            })
        }.resume()
    }
}
