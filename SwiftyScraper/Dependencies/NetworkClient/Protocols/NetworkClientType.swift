//
//  NetworkClientType.swift
//  Networking
//
//  Created by Stanislav Novacek on 23/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Describes a network client.
 Network client is the lowest layer in this framework, it creates `NetworkTask`
 instances (data, download and upload) and manages all session and task delegation.
 */
public protocol NetworkClientType {

    /** Session that this client uses. */
    var session: URLSession! { get }
    /** Delegate. */
    var delegate: NetworkClientDelegate? { get }

    // MARK: Task factories

    /** Creates a new data `NetworkDataTask` with `URLRequest`. */
    func dataTask(with request: URLRequest, serialization: ResponseSerializationType, completion: @escaping (NetworkResult<Data>) -> Void) -> NetworkDataTask

    /** Creates a new download `NetworkDownloadTask` with `URLRequest`. */
    func downloadTask(with request: URLRequest, serialization: ResponseSerializationType, completion: @escaping (NetworkResult<URL>) -> Void) -> NetworkDownloadTask

    /** Creates a new download `NetworkDownloadTask` with resume data. */
    func downloadTask(withResumeData resumeData: Data, serialization: ResponseSerializationType, completion: @escaping (NetworkResult<URL>) -> Void) -> NetworkDownloadTask

    /** Creates a new upload `NetworkUploadTask` with `URLRequest` and a file `URL`. */
    func uploadTask(with request: URLRequest, fromFile fileURL: URL, serialization: ResponseSerializationType, completion: @escaping (NetworkResult<Data>) -> Void) -> NetworkUploadTask

    /** Creates a new download `NetworkUploadTask` with `URLRequest` and body data. */
    func uploadTask(with request: URLRequest, from bodyData: Data, serialization: ResponseSerializationType, completion: @escaping (NetworkResult<Data>) -> Void) -> NetworkUploadTask

}
