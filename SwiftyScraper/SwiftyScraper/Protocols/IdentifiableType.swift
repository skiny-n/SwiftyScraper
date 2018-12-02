//
//  IdentifiableType.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 16/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/** Represents a type that is uniwuely identifiable. */
public protocol IdentifiableType: Hashable {
    
    /** Identifier. */
    var identifier: String { get }
    
}

public extension IdentifiableType {
    
    public var hashValue: Int { return identifier.hashValue }
    
}
