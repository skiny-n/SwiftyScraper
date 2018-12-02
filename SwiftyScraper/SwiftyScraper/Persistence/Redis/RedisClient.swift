//
//  RedisClient.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 16/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation
import Kitura_Redis


/**
 Implementation of a Redis client.
 Manages a connection to a remote Redis instance.
 */
public class RedisClient {
    
    /** Result enum. */
    public enum RedisResult<T> {
        /** Success. */
        case success(T)
        /** Error. Contains error and failed entitites. */
        case error(Error, T)
    }
    
    /** Underlying redis client. */
    public let redis = Redis()
    
    private let host: String
    private let port: Int32
    private let database: Int
    private let password: String?
    
    /** Instantiates a new instance with given host, port number, database number and password (optionally). */
    public init(host: String = "localhost", port: Int32 = 6379, database: Int = 0, password: String? = nil) {
        self.host = host
        self.port = port
        self.database = database
        self.password = password
    }
    
    /** Persorms given operation on a redis database. Opens a connection if not already connected. */
    public func inDatabase<T>(_ block: @escaping (Redis, (RedisResult<T>) -> Void) -> Void, callback: ((Result<T>) -> Void)?) {
        // Check for open connection
        if redis.connected {
            // Connection's open
            block(redis, { result in
                switch result {
                case .success(let value): callback?(.success(value))
                case .error(let error, let wouldBeValue):
                    if error.localizedDescription.contains("Unexpected result received from Redis Status(\"OK\")") {
                        Log.warning { Log.message("Ignoring unexpected OK state from Redis") }
                        callback?(.success(wouldBeValue))
                        return
                    }
                    callback?(.error(.persistence(error)))
                }
            })
        } else {
            // No open connection - connect to a Redis server
            let host = self.host
            let port = self.port
            let database = self.database
            Log.info { Log.message("Redis storage (\(type(of: self))): connecting to redis \(host):\(port)") }
            redis.connect(host: host, port: port) { [weak self] (error) in
                guard let ss = self else { return }
                if let error = error {
                    Log.error { Log.message("Redis storage (\(type(of: ss))): connection failed \(error)") }
                    callback?(.error(.persistence(error)))
                } else {
                    Log.info { Log.message("Redis storage (\(type(of: ss))): successfully connected to redis \(host):\(port)") }
                    // Authenticate
                    if let password = ss.password {
                        Log.info { Log.message("Redis storage (\(type(of: ss))): authenticating ") }
                        ss.redis.auth(password, callback: { [weak self] (error) in
                            guard let ss = self else { return }
                            if let error = error {
                                Log.error { Log.message("Redis storage (\(type(of: ss))): authentication failed \(error)") }
                                callback?(.error(.persistence(error)))
                            } else {
                                // Select database
                                Log.info { Log.message("Redis storage (\(type(of: ss))): selecting database \(database)") }
                                ss.redis.select(ss.database, callback: { [weak self] (error) in
                                    guard let ss = self else { return }
                                    if let error = error {
                                        Log.error { Log.message("Redis storage (\(type(of: self))): selecting database failed \(error)") }
                                        callback?(.error(.persistence(error)))
                                    } else {
                                        ss.inDatabase(block, callback: callback)
                                    }
                                })
                            }
                        })
                    } else {
                        // Select database
                        Log.info { Log.message("Redis storage (\(type(of: ss))): selecting database \(database)") }
                        ss.redis.select(ss.database, callback: { [weak self] (error) in
                            guard let ss = self else { return }
                            if let error = error {
                                Log.error { Log.message("Redis storage (\(type(of: ss))): selecting database failed \(error)") }
                                callback?(.error(.persistence(error)))
                            } else {
                                ss.inDatabase(block, callback: callback)
                            }
                        })
                    }
                }
            }
        }
    }
    
}

/** Helper function for creating `JSON`s from `Data`. */
public func createJSON(fromData: Data?) -> JSON? {
    if let data = fromData, let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? JSON {
        return json
    }
    return nil
}
