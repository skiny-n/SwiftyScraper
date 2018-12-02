//
//  ResponseProcessor.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 13/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/**
 Default implementation of initial response processing.
 Processes status codes and decides what to do next.
 */
open class ResponseProcessor: ResponseInitialProcessingType {
    
    open func process<T>(request: URLRequest, result: NetworkResult<T>) -> ResponseProcessorResult {
        switch result {
        case .success(value: _, task: _):
            // Request OK -> continue
            return .continue
        case .failure(error: let error, task: let task, data: _):
            let failingURL = task.response?.url?.absoluteString ?? request.url?.absoluteString ?? "-unknown-"
            // Inspect error
            switch error {
            case .httpError(let error):
                if [NetworkHTTPError.unauthorized, .forbidden].contains(error) {
                    // Cancel
                    Log.error { Log.message("Response processing -> cancel - not authorized for \(failingURL)") }
                    return .cancel
                } else if [NetworkHTTPError.gone].contains(error) {
                    // Cancel
                    Log.error { Log.message("Response processing -> cancel - url is gone \(failingURL)") }
                    return .cancel
                } else if [NetworkHTTPError.locked].contains(error) {
                    // Die -> we've been lcoked out
                    Log.error { Log.message("Response processing -> die - locked out for \(failingURL)") }
                    return .die
                } else if [NetworkHTTPError.tooManyRequests].contains(error) {
                    // We have to slow down
                    Log.error { Log.message("Response processing -> retry (after 60 seconds) - too many requests \(failingURL)") }
                    return .retry(after: 60)
                } else {
                    // Cancel
                    Log.error { Log.message("Response processing -> cancel - error \(error) for \(failingURL)") }
                    return .cancel
                }
            case .urlError(let error):
                let errorCode = URLError.Code(rawValue: error.code)
                if [URLError.timedOut,
                    .cannotFindHost,
                    .cannotConnectToHost,
                    .networkConnectionLost,
                    .dnsLookupFailed,
                    .notConnectedToInternet].contains(errorCode) {
                    // Retry
                    Log.error { Log.message("Response processing -> retry - error \(errorCode) for \(failingURL)") }
                    return .retry(after: nil)
                } else if [URLError.userAuthenticationRequired, .userCancelledAuthentication].contains(errorCode) {
                    // Cancel
                    Log.error { Log.message("Response processing -> cancel - not authorized for \(failingURL)") }
                    return .cancel
                } else {
                    // Cancel
                    Log.error { Log.message("Response processing -> cancel - error \(errorCode) for \(failingURL)") }
                    return .cancel
                }
            case .unknown:
                // Unknown error -> cancel
                Log.error { Log.message("Response processing -> cancel - error \(error) for \(failingURL)") }
                return .cancel
            }
        }
    }
    
}
