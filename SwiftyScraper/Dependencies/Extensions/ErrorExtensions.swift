//
//  ErrorExtensions.swift
//  Networking-iOS
//
//  Created by Stanislav Novacek on 23/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Error extensions.
 */
public extension NSError {
    
    /** Returns an error for `NSUnderlyingErrorKey` key from `userIfno`. */
    var underlyingError: NSError? { return userInfo[NSUnderlyingErrorKey] as? NSError }
    
    /** Returns a new error instance with given error appended in `userInfo[NSUnderlyingErrorKey]`. */
    func error(byAppending error: NSError) -> NSError {
        var newUserInfo = userInfo
        newUserInfo[NSUnderlyingErrorKey] = error
        return NSError(domain: domain, code: code, userInfo: newUserInfo)
    }
    
}


extension String: Error {
    
    public var localizedDescription: String { return self }
    
}
