//
//  URLExtensions.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 15/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


public extension URL {
    
    var depth: Int {
        return max(0, pathComponents.count - 2)
    }
    
}
