//
//  NetworkTask.swift
//  Networking
//
//  Created by Stanislav Novacek on 08/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 A network task encapsulating a `URLSessionTask` instance.
 Internal, used by `NetworkDataTask`, `NetworkDownloadTask` and `NetworkUploadTask`.
 */
public class NetworkTask {
    
    // MARK: Public properties
    
    /** `NetworkClient` this task was created by. */
    public var client: NetworkClient? { return _client }
    /** `URLSession` this task is associated with. */
    public var session: URLSession? { return _session }
    /** Metrics collected by system for this task. */
    public var metrics: URLSessionTaskMetrics? { return _metrics }
    /** Progress of the task. Computed property. For progress observing use `onProgressChange`. */
    public var progress: Float { return _progress }
    /** Response of this task. Computed property. */
    public var response: HTTPURLResponse? { return _concreteTask.response as? HTTPURLResponse }
    /**
     Custom UUID asociated with this task.
     - May be nil until the task is fully created.
     - Different from `URLSessionTask.identifier`.
     */
    public var customUUID: String? { return _concreteTask.customUUID }
    
    // MARK: Private properties
    
    weak var _client: NetworkClient?
    weak var _session: URLSession?
    var _metrics: URLSessionTaskMetrics?
    var _progress: Float = 0 {
        didSet {
            _onProgressChangeBlock?(oldValue, _progress)
        }
    }
    let _concreteTask: URLSessionTask
    
    /** Data for data and download task. */
    private(set) var data: Data?
    /** URL where the data for download task has been moved after download. */
    var _downloadedDataTemporaryURL: URL?
    /** Serialization used to parse response. */
    var _serialization: ResponseSerializationType = ResponseSerialization.default
    // Observing closures
    var _needsNewBodyStreamBlock: (() -> InputStream?)?
    var _authChallengeBlock: ((URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?))?
    var _redirectBlock: ((HTTPURLResponse, URLRequest) -> URLRequest?)?
    var _onProgressChangeBlock: ((Float, Float) -> Void)?
    // Completion closures
    var _onCompletionBlockData: ((NetworkResult<Data>) -> Void)?
    var _onCompletionBlockURL: ((NetworkResult<URL>) -> Void)?
    // Upload task progress
    var _bytesSent: Int64 = 0
    var _bytesExpectedToSent: Int64 = NSURLSessionTransferSizeUnknown
    // Data and download task progress
    var _bytesWritten: Int64 = 0
    var _bytesExpectedToWrite: Int64 = NSURLSessionTransferSizeUnknown
    
    // MARK: Lifecycle
    
    /// Initializes a new instance with given session task.
    init (sessionTask: URLSessionTask) {
        _concreteTask = sessionTask
    }
    
    func didReceive(data: Data) {
        if self.data == nil {
            self.data = data
        } else {
            self.data!.append(data)
        }
    }
    
    
    // MARK: Public functions
    
    /** Starts or resumes the task. See: `NSURLSessionTask.resume()`. */
    public func start() { /* no-op */ }
    
    /** Used to supply the task with new body stream. */
    public func onNeedsNewBodyStream(_ block: @escaping () -> InputStream?) -> NetworkTask {
        _needsNewBodyStreamBlock = block
        return self
    }
    
    /**
     The task has received a request specific authentication challenge.
     If this is not implemented, the default handling disposition will be used.
     */
    public func onAuthenticationChallenge(_ block: @escaping (URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?)) -> NetworkTask {
        _authChallengeBlock = block
        return self
    }
    
    /**
     Called on HTTP redirection. An HTTP request is attempting to perform a redirection to a different URL.
     You must invoke the completion routine to allow the redirection, allow the redirection with a modified request, or
     pass nil to the completionHandler to cause the body of the redirection response to be delivered as the
     payload of this request. The default is to follow redirections.
     */
    public func onHTTPRedirect(_ block: @escaping (HTTPURLResponse, URLRequest) -> URLRequest?) -> NetworkTask {
        _redirectBlock = block
        return self
    }
    
    /**
     Called when progress of the task changes.
     Closure params: (old progress, new progress).
     Prgoress values: <0.0;1.0>.
     */
    public func onProgressChange(_ block: @escaping (Float, Float) -> Void) -> NetworkTask {
        _onProgressChangeBlock = block
        return self
    }
    
}

extension NetworkTask: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String { return _concreteTask.description }
    public var debugDescription: String { return _concreteTask.debugDescription }
    
}

extension NetworkTask: Equatable
{
    /**
     Two `NetworkTask` instances are == if
     their inner `URLSessionTask`s are == or if
     their inner `URLSessionTask.taskIdentifier` as ==.
     */
    public static func ==(_ lhs: NetworkTask, _ rhs: NetworkTask) -> Bool {
        if let uuid1 = lhs._concreteTask.customUUID, let uuid2 = rhs._concreteTask.customUUID {
            return uuid1 == uuid2
        } else {
            return lhs._concreteTask.taskIdentifier == rhs._concreteTask.taskIdentifier
        }
    }
    
}

/**
 Represents a data task.
 */
public final class NetworkDataTask: NetworkTask {
    
    /** Data task associated with this task. */
    public var dataTask: URLSessionDataTask {
        return _concreteTask as! URLSessionDataTask
    }
    
    public override func start() {
        dataTask.resume()
        Log.debug {
            Log.message("Networking: Data task started").attachInfo(self)
        }
    }
    
    /**
     Cancels the task. Returns immediately but some delegate calls may still be made.
     See: `NSURLSessionTask.cancel()` for more info.
     */
    public func cancel() {
        dataTask.cancel()
        Log.debug {
            Log.message("Networking: Data task cancelled").attachInfo(self)
        }
    }
    
}

/**
 Represents a download task.
 */
public final class NetworkDownloadTask: NetworkTask {
    
    /** Download task associated with this task. */
    public var downloadTask: URLSessionDownloadTask {
        return _concreteTask as! URLSessionDownloadTask
    }
    /** Number of bytes received so far. */
    var bytesReceived: Int64 { return _bytesWritten }
    /** Number of bytes expected to receive. (May be `NSURLSessionTransferSizeUnknown` for unknown states. */
    var bytesExpectedToReceived: Int64 { return _bytesExpectedToWrite }
    
    public override func start() {
        downloadTask.resume()
        Log.debug {
            Log.message("Networking: Download task started").attachInfo(self)
        }
    }
    
    /**
     Cancels the task. Returns immediately but some delegate calls may still be made.
     See: `NSURLSessionTask.cancel()` for more info.
     */
    public func cancel() {
        downloadTask.cancel()
        Log.debug {
            Log.message("Networking: Download task cancelled").attachInfo(self)
        }
    }
    
    /**
     Cancels the task. Some delegate calls may still be made.
     See: `NSURLSessionDownloadTask.cancel(byProducingResumeData)` for more info..
     */
    public func cancel(byProducingResumeData completion: @escaping (Data?) -> Swift.Void) {
        downloadTask.cancel { (data) in
            completion(data)
            Log.debug {
                Log.message("Networking: Download task cancelled with resume data? \(data != nil)").attachInfo(self)
            }
        }
    }
    
}

/**
 Represents an upload task.
 */
public final class NetworkUploadTask: NetworkTask {
    
    /** Upload task associated with this task. */
    public var uploadTask: URLSessionUploadTask {
        return _concreteTask as! URLSessionUploadTask
    }
    /** Number of bytes sent do far. */
    var bytesSent: Int64 { return _bytesSent }
    /** Number of bytes expected to sent. (May be `NSURLSessionTransferSizeUnknown` for unknown states. */
    var bytesExpectedToSent: Int64 { return _bytesExpectedToSent }
    
    public override func start() {
        uploadTask.resume()
        Log.debug {
            Log.message("Networking: Upload task started").attachInfo(self)
        }
    }
    
    /**
     Cancels the task. Returns immediately but some delegate calls may still be made.
     See: `NSURLSessionTask.cancel()` for more info.
     */
    public func cancel() {
        uploadTask.cancel()
        Log.debug {
            Log.message("Networking: Upload task cancelled").attachInfo(self)
        }
    }

}

// MARK: URLSessionTask

extension URLSessionTask
{
    private static var kUUIDPropertyKey: UInt8 = 0
    /** UUID associated with this task. Custom property, will be `nil` if hasn't been set yet. */
    var customUUID: String? {
        get { return objc_getAssociatedObject(self, &URLSessionTask.kUUIDPropertyKey) as? String }
        set { objc_setAssociatedObject(self, &URLSessionTask.kUUIDPropertyKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}


