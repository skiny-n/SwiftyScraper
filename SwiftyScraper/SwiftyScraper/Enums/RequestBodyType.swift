//
//  RequestBodyType.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 14/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/** Represents an HTTP request body type and associated data. */
public enum RequestBodyType {
    
    /** URL encoded body type. */
    case url(JSON)
    /** JSON encoded body type. */
    case json(JSON)
    /** XML encoded body type. */
    case xml(String)
    
}
