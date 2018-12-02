//
//  Result.swift
//  Networking
//
//  Created by Stanislav Novacek on 06/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Network result.
 
 - success: Contains value (usually `Data`) and corresponding response
 - failure: Contains an error, response and data
 */
public enum NetworkResult<SuccessValue> {
    
    case success(value: SuccessValue?, task: NetworkTask)
    case failure(error: NetworkError, task: NetworkTask, data: Data?)
    
    /** Returns `value` from successful case, `nil` from failure. Convenience. */
    public var value: SuccessValue? {
        switch self {
        case .success(let value, _): return value
        case .failure(_): return nil
        }
    }

    /** Returns `Error` from failure case, `nil` from success. Convenience. */
    public var error: Error? {
        switch self {
        case .success(_): return nil
        case .failure(let error, _, _): return error
        }
    }
    
    /** Returns corresopnding response if any exists. */
    public var response: HTTPURLResponse? {
        switch self {
        case .success(_, let task): return task._concreteTask.response as? HTTPURLResponse
        case .failure(_, let task, _): return task._concreteTask.response as? HTTPURLResponse
        }
    }
    
}

public extension NetworkResult {
    
    /** Whether this error represents paused downlaod task. */
    var isPausedDownloadWithResumeData: Bool {
        switch self {
        case .success(_):
            return false
        case .failure(error: let e, task: _, data: let d):
            switch e {
            case .urlError(let urlE):
                return urlE.code == NSURLErrorCancelled && d != nil
            default:
                return false
            }
        }
    }
    
}



