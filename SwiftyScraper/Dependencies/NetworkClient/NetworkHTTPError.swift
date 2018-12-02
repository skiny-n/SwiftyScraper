//
//  HTTPError.swift
//  Networking
//
//  Created by Stanislav Novacek on 06/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Enum representing an HTTP error.
 */
public enum NetworkHTTPError: Int {
    
    public static let domain = "cz.skiny.n.swiftyscraper.networking.network-client.http-error-domain"
    
    case badRequest = 400
    case unauthorized = 401
    case paymentRequired = 402
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case notAcceptable = 406
    case proxyAuthenticationRequired = 407
    case requestTimeout = 408
    case conflict = 409
    case gone = 410
    case lengthRequired = 411
    case preconditionFailed = 412
    case payloadTooLarge = 413
    case uriTooLong = 414
    case unsupportedMediaType = 415
    case rangeNotSatisfiable = 416
    case expectationFailed = 417
    case iAmATeapot = 418
    case misdirectedRequest = 421
    case unprocessableEntity = 422
    case locked = 423
    case failedDependency = 424
    case upgradeRequired = 426
    case preconditionRequired = 428
    case tooManyRequests = 429
    case requestHeaderFieldsTooLarge = 431
    case unavailableForLegalReasons = 451
    
    case internalServerError = 500
    case notImplemented = 501
    case badGateway = 502
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    case httpVersionNotSupported = 505
    case variantAlsoNegotiates = 506
    case insufficientStorage = 507
    case loopDetected = 508
    case notExtended = 510
    case networkAuthenticationRequired = 511
    
    public var code: Int { return rawValue }
    
    public var localizedDescription: String { return "http.error.\(rawValue)".localized }
    
    public func toError() -> NSError {
        return NSError(domain: NetworkHTTPError.domain, code: code, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
    }
    
}
