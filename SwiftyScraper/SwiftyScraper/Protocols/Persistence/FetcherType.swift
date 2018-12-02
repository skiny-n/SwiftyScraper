//
//  FetcherType.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 13/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/**
 Interface for fetching entities.
 */
public protocol FetcherType {
    
    /** Entity. */
    associatedtype FetchedEntity
    
    /** Fetches all entities. */
    func fetchAll(callback: @escaping (Result<[FetchedEntity]>) -> Void)
    /** Fetches first entity.. */
    func fetchFirst(callback: @escaping (Result<FetchedEntity?>) -> Void)
    /** Fetches first entity that satisfies the given predicate. */
    func fetchFirst(where predicate: @escaping (FetchedEntity) -> Bool, callback: @escaping (Result<FetchedEntity?>) -> Void)
    /** Fetches last entity. */
    func fetchLast(callback: @escaping (Result<FetchedEntity?>) -> Void)
    /** Fetches all the entities that satisfy the given predicate. */
    func fetchAll(where predicate: @escaping (FetchedEntity) -> Bool, callback: @escaping (Result<[FetchedEntity]>) -> Void)
    
}
