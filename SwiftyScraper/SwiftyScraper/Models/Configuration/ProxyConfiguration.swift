//
//  ProxyConfiguration.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 13/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/** Proxy configuration struct. */
public struct ProxyConfiguration {
    
    /** Proxy host. */
    public let host: String
    /** Proxy port. */
    public let port: Int
    /** Username to use for authentication. */
    public let username: String?
    /** Password to use for authentication. */
    public let password: String?
    
    /** Instantiates a new instane with given `JSON` payload. Returns `nil` if the payload in invalid. */
    init?(json: JSON) {
        if let host = json["host"] as? String, let port = json["port"] as? Int {
            self.host = host
            self.port = port
            self.username = json["username"] as? String
            self.password = json["password"] as? String
        } else {
            Log.error { Log.message("Invalid proxy json: \(json)") }
            return nil
        }
    }
    
}
