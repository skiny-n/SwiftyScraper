//
//  MemoryPersistenceStorage.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 13/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation



/**
 In-memory storage for persisting associated entities.
 */
public final class MemoryPersistenceStorage<Entity: IdentifiableType>: PersistorType & FetcherType {

    public typealias PersistedEntity = Entity
    public typealias FetchedEntity = Entity
    
    private let entries = SynchronizedArray<Entity>()
    
    public init() { }
    
    // MARK: Persistor type
    
    public func persist(entity: Entity, callback: ((Result<Entity>) -> Void)?) {
        entries.append(entity)
        callback?(.success(entity))
    }
    
    public func persist(entities: [Entity], callback: ((Result<[Entity]>) -> Void)?) {
        entries.append(entities)
        callback?(.success(entities))
    }
    
    public func removeAll(where predicate: @escaping (Entity) -> Bool, callback: ((Result<Void>) -> Void)?) {
        entries.removeAll(where: predicate)
        callback?(.success(()))
    }
    
    public func removeAll(callback: ((Result<Void>) -> Void)?) {
        entries.removeAll { (_) in callback?(.success(())) }
    }
    
    // MARK: Fetcher type
    
    public func fetchAll(callback: @escaping (Result<[Entity]>) -> Void) {
        callback(.success(entries.compactMap({ $0 })))
    }
    
    public func fetchAll(where predicate: @escaping (Entity) -> Bool, callback: @escaping (Result<[Entity]>) -> Void) {
        callback(.success(entries.filter(predicate)))
    }
    
    public func fetchFirst(callback: @escaping (Result<Entity?>) -> Void) {
        callback(.success(entries.first))
    }
    
    public func fetchFirst(where predicate: @escaping (Entity) -> Bool, callback: @escaping (Result<Entity?>) -> Void) {
        callback(.success(entries.first(where: predicate)))
    }
    
    public func fetchLast(callback: @escaping (Result<Entity?>) -> Void) {
        callback(.success(entries.last))
    }

}

