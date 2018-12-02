//
//  RequestBuilderType.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 13/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/** Describes a request builder. */
public protocol RequestBuilderType {
    
    /** Creates an HTTP request with given method, URL, parameters, body and headers. */
    func buildRequest(method: HTTPMethod, url: String, parameters: JSON?, body: RequestBodyType?, headers: [String: String]) -> URLRequest?
    
}
