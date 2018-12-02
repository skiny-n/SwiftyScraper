//
//  NetworkError.swift
//  Networking
//
//  Created by Stanislav Novacek on 06/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Network error. Represents errors thrown/returned by a `NetworkClientType` instances.
 */
public enum NetworkError: Error {
    
    public static let domain = "cz.skiny.n.swiftyscraper.networking.network-error-domain"
    
    /** HTTP error. */
    case httpError(NetworkHTTPError)
    /** URL error. */
    case urlError(NSError)
    /** Unknown error. */
    case unknown
    
    /** Code. This call is forwarded to inner errors. */
    public var code: Int {
        switch self {
        case .httpError(let err): return err.rawValue
        case .urlError(let err): return err.code
        case .unknown: return -1
        }
    }
    
    /** Localized description. This call is forwarded to inner errors. */
    public var localizedDescription: String {
        switch self {
        case .httpError(let err): return err.localizedDescription
        case .urlError(let err): return err.localizedDescription
        case .unknown: return "networking.error.unknown".localized
        }
    }

    /** `NSError` representation. Contains inner errors in `userInfo[NSUnderlyingErrorKey]`. */
    public func toError() -> NSError {
        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: localizedDescription]
        switch self {
        case .httpError(let e): userInfo[NSUnderlyingErrorKey] = e.toError()
        case .urlError(let e): userInfo[NSUnderlyingErrorKey] = e
        case .unknown: break
        }
        return NSError(domain: NetworkError.domain, code: code, userInfo: userInfo)
    }
    
}
