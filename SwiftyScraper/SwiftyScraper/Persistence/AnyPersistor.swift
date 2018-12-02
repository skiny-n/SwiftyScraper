//
//  AnyPersistor.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 14/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Type erasure for persistors.
 */
public class AnyPersistor<Entity: IdentifiableType>: PersistorType {
    
    public typealias PersistedEntity = Entity
    
    private let _persist: (Entity, ((Result<Entity>) -> Void)?) -> Void
    private let _persistMore: ([Entity], ((Result<[Entity]>) -> Void)?) -> Void
    
    private let _removeAllWhere: (@escaping (Entity) -> Bool, ((Result<Void>) -> Void)?) -> Void
    private let _removeAll: (((Result<Void>) -> Void)?) -> Void
    
    public init<T: PersistorType>(_ persistor: T) where T.PersistedEntity == Entity {
        self._persist = persistor.persist
        self._persistMore = persistor.persist
        self._removeAllWhere = persistor.removeAll
        self._removeAll = persistor.removeAll
    }
    
    public func persist(entity: Entity, callback: ((Result<Entity>) -> Void)?) {
        _persist(entity, callback)
    }
    
    public func persist(entities: [Entity], callback: ((Result<[Entity]>) -> Void)?) {
        _persistMore(entities, callback)
    }
    
    public func removeAll(where predicate: @escaping (Entity) -> Bool, callback: ((Result<Void>) -> Void)?) {
        _removeAllWhere(predicate, callback)
    }
    
    public func removeAll(callback: ((Result<Void>) -> Void)?) {
        _removeAll(callback)
    }
    
}
