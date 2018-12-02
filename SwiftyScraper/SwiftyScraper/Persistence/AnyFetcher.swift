//
//  AnyFetcher.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 16/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/**
 Type erasure for fetchers.
 ¨ */
public class AnyFetcher<Entity: IdentifiableType>: FetcherType {
    
    public typealias FetchedEntity = Entity
    
    private let _fetchAll: (@escaping (Result<[Entity]>) -> Void) -> Void
    private let _fetchAllWhere: (@escaping (Entity) -> Bool, @escaping (Result<[Entity]>) -> Void) -> Void
    private let _fetchFirst: (@escaping (Result<Entity?>) -> Void) -> Void
    private let _fetchFirstWhere: (@escaping (Entity) -> Bool, @escaping (Result<Entity?>) -> Void) -> Void
    private let _fetchLast: (@escaping (Result<Entity?>) -> Void) -> Void
    
    public init<T: FetcherType>(_ fetcher: T) where T.FetchedEntity == Entity {
        self._fetchAll = fetcher.fetchAll
        self._fetchAllWhere = fetcher.fetchAll
        self._fetchFirst = fetcher.fetchFirst
        self._fetchFirstWhere = fetcher.fetchFirst
        self._fetchLast = fetcher.fetchLast
    }
    
    public func fetchAll(callback: @escaping (Result<[Entity]>) -> Void) {
        _fetchAll(callback)
    }
    
    public func fetchAll(where predicate: @escaping (Entity) -> Bool, callback: @escaping (Result<[Entity]>) -> Void) {
        _fetchAllWhere(predicate, callback)
    }
    
    public func fetchFirst(callback: @escaping (Result<Entity?>) -> Void) {
        _fetchFirst(callback)
    }
    
    public func fetchFirst(where predicate: @escaping (Entity) -> Bool, callback: @escaping (Result<Entity?>) -> Void) {
        _fetchFirstWhere(predicate, callback)
    }
    
    public func fetchLast(callback: @escaping (Result<Entity?>) -> Void) {
        _fetchLast(callback)
    }
    
}
