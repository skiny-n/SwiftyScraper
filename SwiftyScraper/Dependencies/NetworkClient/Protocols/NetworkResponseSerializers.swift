//
//  NetworkResponseSerializers.swift
//  Networking
//
//  Created by Stanislav Novacek on 08/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Protocol used for serializing responses from `URLSessionTask`s to `NetworkResult`s.
 */
public protocol ResponseSerializationType {
    
    /**
     Serializes given network response.
     - parameters:
         - value:     Fetched value
         - task:      A network task
         - error:     Error from the server
     */
    func serialize<T>(value: T?, task: NetworkTask, error: Error?) -> NetworkResult<T>
    
}

/**
 Default implementation of `ResponseSerializationType`.
 */
public struct ResponseSerialization: ResponseSerializationType {
    
    /** Shared default implementation of `ResponseSerializationType`. */
    public static let `default` = ResponseSerialization()
    
    public func serialize<T>(value: T?, task: NetworkTask, error: Error?) -> NetworkResult<T> {
        // URL error
        if error != nil {
            if let error = error as NSError?, error.domain == NSURLErrorDomain {
                return .failure(error: .urlError(error), task: task, data: value as? Data)
            } else {
                return .failure(error: .unknown, task: task, data: value as? Data)
            }
        }
        // HTTP response
        else if let response = task.response {
            if (200 ..< 400).contains(response.statusCode) {
                return .success(value: value, task: task)
            } else if let httpError = NetworkHTTPError(rawValue: response.statusCode) {
                return .failure(error: .httpError(httpError), task: task, data: value as? Data)
            }
        }
        // Sorry, we're doing just the classics 
        return .failure(error: .unknown, task: task, data: value as? Data)
    }
    
}
