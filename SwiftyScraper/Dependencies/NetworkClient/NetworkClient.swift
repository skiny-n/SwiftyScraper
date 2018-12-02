//
//  Client.swift
//  Networking
//
//  Created by Stanislav Novacek on 06/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Network client based upon `URLSession`.
 Offers creating data/download/upload tasks and performs first serialization of their responses.
 
 Each client has its own operation queue on which all delegation happens, therefore every
 completion or other utility closures associated with network tasks are not execuded on the main queue.
 */
public final class NetworkClient: NSObject, NetworkClientType {
    
    // Public
    
    /** URLSession that this client uses. */
    public private(set) var session: URLSession!
    /** Delegate. */
    public private(set) var delegate: NetworkClientDelegate?
    
    // Private
    
    /** Operation queue - delagetion queue. */
    private lazy var operationQueue: OperationQueue = {
        let q = OperationQueue()
        q.underlyingQueue = operationQueueDQ
        return q
    }()
    private let operationQueueDQ = DispatchQueue(label: "cz.skiny.n.swiftyscraper.networking.clientDelegatingQueue")
    /** Queue used for accessing `allTasks` storage. */
    private lazy var taskModificationsQueue: OperationQueue = {
        let q = OperationQueue()
        q.underlyingQueue = taskModificationsQueueDQ
        q.maxConcurrentOperationCount = 1
        return q
    }()
    private let taskModificationsQueueDQ = DispatchQueue(label: "cz.skiny.n.swiftyscraper.networking.taskModificationsQueue")
    /** All ongoing tasks. [UUID: NetworkTask]  */
    private var allTasks: [String: NetworkTask] = [:]
    
    // MARK: Lifecycle
    
    /** Initializes a new client with given parameters. These parameters corresponds to those for `URLSession`. */
    public init(configuration: URLSessionConfiguration = URLSessionConfiguration.default, delegate: NetworkClientDelegate? = nil) {
        super.init()
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)
        self.delegate = delegate
        // Clean up any left over trashy downloads.
        cleanOldTemporaryDownloads()
    }
    
    // MARK: NetworkClientType (task factories)
    
    public func dataTask(with request: URLRequest, serialization: ResponseSerializationType = ResponseSerialization.default, completion: @escaping (NetworkResult<Data>) -> Void) -> NetworkDataTask {
        let task = createDataTask(with: session.dataTask(with: request), serialization: serialization)
        task._onCompletionBlockData = completion
        addTask(task)
        return task
    }
    
    public func downloadTask(with request: URLRequest, serialization: ResponseSerializationType = ResponseSerialization.default, completion: @escaping (NetworkResult<URL>) -> Void) -> NetworkDownloadTask {
        let task = createDownloadTask(with: session.downloadTask(with: request), serialization: serialization)
        task._onCompletionBlockURL = completion
        addTask(task)
        return task
    }
    
    public func downloadTask(withResumeData resumeData: Data, serialization: ResponseSerializationType = ResponseSerialization.default, completion: @escaping (NetworkResult<URL>) -> Void) -> NetworkDownloadTask {
        let task = createDownloadTask(with: session.downloadTask(withResumeData: resumeData), serialization: serialization)
        task._onCompletionBlockURL = completion
        addTask(task)
        return task
    }
    
    public func uploadTask(with request: URLRequest, fromFile fileURL: URL, serialization: ResponseSerializationType = ResponseSerialization.default, completion: @escaping (NetworkResult<Data>) -> Void) -> NetworkUploadTask {
        let task = createUploadTask(with: session.uploadTask(with: request, fromFile: fileURL), serialization: serialization)
        task._onCompletionBlockData = completion
        addTask(task)
        return task
    }
    
    public func uploadTask(with request: URLRequest, from bodyData: Data, serialization: ResponseSerializationType = ResponseSerialization.default, completion: @escaping (NetworkResult<Data>) -> Void) -> NetworkUploadTask {
        let task = createUploadTask(with: session.uploadTask(with: request, from: bodyData), serialization: serialization)
        task._onCompletionBlockData = completion
        addTask(task)
        return task
    }
    
    // MARK: - Private
    // MARK: Helpers
    
    /** Calculates progress <0;1> from given states. */
    private func calculateProgress(_ current: Int64, total: Int64) -> Float {
        if total != NSURLSessionTransferSizeUnknown && total != 0 {
            let progress = Float(current) / Float(total)
            return min(max(progress, 0.0), 1.0)
        }
        return 0.0
    }
    
    // MARK: Helpers - Task management
    
    private func createDataTask(with sessionTask: URLSessionTask, serialization: ResponseSerializationType) -> NetworkDataTask {
        let t = NetworkDataTask(sessionTask: sessionTask)
        t._serialization = serialization
        configureTask(t)
        return t
    }
    
    private func createDownloadTask(with sessionTask: URLSessionTask, serialization: ResponseSerializationType) -> NetworkDownloadTask {
        let t = NetworkDownloadTask(sessionTask: sessionTask)
        t._serialization = serialization
        configureTask(t)
        return t
    }
    
    private func createUploadTask(with sessionTask: URLSessionTask, serialization: ResponseSerializationType) -> NetworkUploadTask {
        let t = NetworkUploadTask(sessionTask: sessionTask)
        t._serialization = serialization
        configureTask(t)
        return t
    }
    
    /** Configures (associates metadata) given task. */
    private func configureTask(_ task: NetworkTask) {
        task._session = session
        task._client = self
        task._concreteTask.customUUID = UUID().uuidString
    }
    
    /** Creates a `NetworkTask` instance for given `URLSession` task. */
    private func networkTask(for sessionTask: URLSessionTask, _ completion: @escaping (NetworkTask?) -> Void) {
        taskModificationsQueue.addOperation { [weak self] in
            guard let ss = self else {
                completion(nil)
                return
            }
            if let uuid = sessionTask.customUUID {
                ss.operationQueue.addOperation { completion(self?.allTasks[uuid]) }
            } else {
                ss.operationQueue.addOperation { completion(nil) }
            }
        }
    }
    
    /** Removes given task from `allTasks` storage. */
    private func removeTask(_ task: NetworkTask) {
        guard let uuid = task._concreteTask.customUUID else {
            assertionFailure("Networking: Could not get uuid while removing a task!")
            return
        }
        taskModificationsQueue.addOperation { [weak self] in
            guard let ss = self else { return }
            ss.allTasks[uuid] = nil
            let count = ss.allTasks.count
            Log.debug {
                Log.message("Networking: Task removed. Total count: \(count)")
            }
        }
    }
    
    /** Adds given task to `allTasks` storage. */
    private func addTask(_ task: NetworkTask) {
        guard let uuid = task._concreteTask.customUUID else {
            assertionFailure("Networking: Could not get uuid while adding a task!")
            return
        }
        taskModificationsQueue.addOperation { [weak self] in
            guard let ss = self else { return }
            ss.allTasks[uuid] = task
            let count = ss.allTasks.count
            Log.debug {
                Log.message("Networking: Task added. Total count: \(count)")
            }
        }
    }
    
    // MARK: Helpers - Temporary downloads
    
    /** Moves freshly downloaded file to temporary downloads folder (because system automatically deletes this file from its temp localiton). */
    private func moveDownloadedFileToTemporary(_ fileURL: URL) -> URL {
        let tempURL = temporaryDownloadDirectory().appendingPathComponent(fileURL.lastPathComponent)
        _ = try? FileManager.default.moveItem(at: fileURL, to: tempURL)
        Log.debug {
            Log.message("Networking: Moved downloaded file to temporary location: \(tempURL)")
        }
        return tempURL
    }
    
    /** Returns URL of directory used for temporary downloads. */
    private func temporaryDownloadDirectory() -> URL {
        let folderName = "networking_client_temporaryDownloads"
        let fm = FileManager.default
        let tempDirectory = fm.temporaryDirectory.appendingPathComponent(folderName)
        if !fm.fileExists(atPath: tempDirectory.path) {
            _ = try? fm.createDirectory(at: tempDirectory, withIntermediateDirectories: false, attributes: nil)
        }
        return tempDirectory
    }
    
    /** Cleans any temporary download that may have been left over. Usually when a lazy developer didn't use the download. */
    private func cleanOldTemporaryDownloads() {
        // Get all files in the download temporary directory
        let fm = FileManager.default
        let downloadDirectory = temporaryDownloadDirectory()
        guard let files = try? fm.contentsOfDirectory(at: downloadDirectory, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles) else {
            return
        }
        // Filter files that have not been modified longer than 8 hours
        let deadline = Date().addingTimeInterval(-60*60*8)
        for fileURL in files.filter({
            if let values = try? $0.resourceValues(forKeys: [.contentModificationDateKey]), let modified = values.contentModificationDate {
                return modified < deadline
            }
            return false
        }) {
            // Remove trash downloads
            _ = try? fm.removeItem(at: fileURL)
            Log.debug {
                Log.message("Networking: Removed old download: \(fileURL.lastPathComponent)")
            }
        }
    }
    
}


// MARK: URLSessionDelegate

extension NetworkClient: URLSessionDelegate {
    
    #if !os(macOS)
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        delegate?.networkClientDidFinishBackgroundEvents(self)
    }
    #endif
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        // Clean up
        taskModificationsQueue.addOperation { [weak self] in
            self?.allTasks.values.forEach { task in
                task._onCompletionBlockData?(.failure(error: .unknown, task: task, data: nil))
                task._onCompletionBlockURL?(.failure(error: .unknown, task: task, data: nil))
            }
            self?.allTasks.removeAll()
        }
        // Notify delegate
        delegate?.networkClient(self, didBecomeInvalidWithError: error)
        Log.debug {
            Log.message("Networking: Session invalidated.")
        }
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let delegate = delegate {
            delegate.networkCLient(self, didReceive: challenge, completionHandler: completionHandler)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
}

// MARK: URLSessionDataDelegate

extension NetworkClient: URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        networkTask(for: dataTask) { $0?.didReceive(data: data) }
    }
    
}

// MARK: URLSessionTaskDelegate

extension NetworkClient: URLSessionTaskDelegate {
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        networkTask(for: task) { $0?._metrics = metrics }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        networkTask(for: task) { [weak self] (t) in
            if let ss = self, let t = t {
                t._progress = ss.calculateProgress(totalBytesSent, total: totalBytesExpectedToSend)
                t._bytesSent = totalBytesSent
                t._bytesExpectedToSent = totalBytesExpectedToSend
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        networkTask(for: task) { [weak self] (t) in
            guard let t = t else {
                Log.error {
                    Log.message("Networking: URLSessionTask finished but its NetworkTask was not found!").attachInfo(task)
                }
                return
            }
            // Get needed stuff
            let data = t.data
            let error = error ?? task.error
            let tempURL = t._downloadedDataTemporaryURL
            
            // Download tasks
            if t._concreteTask is URLSessionDownloadTask {
                let result = t._serialization.serialize(value: tempURL, task: t, error: error)
                // Notify
                if let callback = t._onCompletionBlockURL {
                    callback(result)
                }
                Log.debug {
                    Log.message("Networking: Download task finished").attachInfo(result)
                }
            }
            // Data and upload tasks
            else {
                let result = t._serialization.serialize(value: data, task: t, error: error)
                if t._concreteTask is URLSessionDataTask {
                    Log.debug {
                        Log.message("Networking: Data task finished").attachInfo(result)
                    }
                } else {
                    Log.debug {
                        Log.message("Networking: Upload task finished").attachInfo(result)
                    }
                }
                // Notify
                if let callback = t._onCompletionBlockData {
                    callback(result)
                }
            }
            
            // Cleanup
            self?.removeTask(t)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        networkTask(for: task) { (t) in
            if let block = t?._needsNewBodyStreamBlock {
                completionHandler(block())
            } else {
                completionHandler(nil)
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        networkTask(for: task) { (t) in
            if let block = t?._authChallengeBlock {
                let result = block(challenge)
                completionHandler(result.0, result.1)
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        networkTask(for: task) { (t) in
            if let block = t?._redirectBlock {
                completionHandler(block(response, request))
            } else {
                completionHandler(request)
            }
        }
    }
    
}


// MARK: URLSessionDownloadDelegate

extension NetworkClient: URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let newLocation = moveDownloadedFileToTemporary(location)
        networkTask(for: downloadTask) { (t) in
            t?._downloadedDataTemporaryURL = newLocation
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        networkTask(for: downloadTask) { [weak self] (t) in
            if let ss = self, let t = t {
                t._progress = ss.calculateProgress(fileOffset, total: expectedTotalBytes)
                t._bytesWritten = fileOffset
                t._bytesExpectedToWrite = expectedTotalBytes
            }
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        networkTask(for: downloadTask) { [weak self] (t) in
            if let ss = self, let t = t {
                t._progress = ss.calculateProgress(totalBytesWritten, total: totalBytesExpectedToWrite)
                t._bytesWritten = totalBytesWritten
                t._bytesExpectedToWrite = totalBytesExpectedToWrite
            }
        }
    }
    
}

