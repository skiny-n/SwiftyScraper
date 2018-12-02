//
//  AnyPersistenceStorage.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 13/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/**
 Type eraser for persistence storages.
 */
public class AnyPersistenceStorage<Entity: IdentifiableType>: PersistorType & FetcherType {
    
    public typealias FetchedEntity = Entity
    public typealias PersistedEntity = Entity
    
    private let basePersistor: AnyPersistor<Entity>
    private let baseFetcher: AnyFetcher<Entity>
    
    public init<T: PersistorType & FetcherType>(_ storage: T) where T.FetchedEntity == Entity, T.PersistedEntity == Entity {
        self.basePersistor = AnyPersistor(storage)
        self.baseFetcher = AnyFetcher(storage)
    }
    
    public func persist(entity: Entity, callback: ((Result<Entity>) -> Void)?) {
        basePersistor.persist(entity: entity, callback: callback)
    }
    
    public func persist(entities: [Entity], callback: ((Result<[Entity]>) -> Void)?) {
        basePersistor.persist(entities: entities, callback: callback)
    }
    
    public func removeAll(where predicate: @escaping (Entity) -> Bool, callback: ((Result<Void>) -> Void)?) {
        basePersistor.removeAll(where: predicate, callback: callback)
    }
    
    public func removeAll(callback: ((Result<Void>) -> Void)?) {
        basePersistor.removeAll(callback: callback)
    }
    
    public func fetchAll(callback: @escaping (Result<[Entity]>) -> Void) {
        baseFetcher.fetchAll(callback: callback)
    }
    
    public func fetchAll(where predicate: @escaping (Entity) -> Bool, callback: @escaping (Result<[Entity]>) -> Void) {
        baseFetcher.fetchAll(where: predicate, callback: callback)
    }
    
    public func fetchFirst(callback: @escaping (Result<Entity?>) -> Void) {
        baseFetcher.fetchFirst(callback: callback)
    }
    
    public func fetchFirst(where predicate: @escaping (Entity) -> Bool, callback: @escaping (Result<Entity?>) -> Void) {
        baseFetcher.fetchFirst(where: predicate, callback: callback)
    }
    
    public func fetchLast(callback: @escaping (Result<Entity?>) -> Void) {
        baseFetcher.fetchLast(callback: callback)
    }
    
}
