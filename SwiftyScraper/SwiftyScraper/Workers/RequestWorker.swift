//
//  RequestWorker.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 12/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/** A reqeust worker. Manages downloading given `URLEntry` instances. */
open class RequestWorker {
    
    /** Finish callback. Notifies tha a URL entry has finished processing with a result. */
    public typealias FinishCallback = (ResponseProcessorResult, RequestWorker, URLEntry?, Data?, HTTPURLResponse?, NetworkError?) -> Void
    
    /** Identifier. */
    public let id = UUID().uuidString
    /** Configuration. */
    public let configuration: RequestWorkerConfiguration
    /** A request builder. */
    public let requestBuilder: RequestBuilderType
    /** A response processor. */
    public let responseProcessor: ResponseInitialProcessingType
    /** Number of lives this worker has left. When this reaches to zero, the worker dies. */
    public private(set) var lives: Int {
        didSet {
            if lives <= 0 {
                isRunning = false
                onFinished(.die, self, nil, nil, nil, nil)
            }
        }
    }
    /** Whether or not the workner is running. */
    public private(set) var isRunning: Bool = false
    /** Whether this worker is alive and ready for work. */
    public var isIdle: Bool { return lives > 0 && !isRunning }
    
    
    private var onFinished: FinishCallback
    /// Network client.
    private lazy var client: NetworkClientType = { return createNetworkClient() }()
    /// Last response time - how long it took before a response got in.
    private var lastResponseTime: TimeInterval = 0
    /// Calculates newxt delay for a request.
    private var nextDelay: TimeInterval {
        return RequestBuilder.randomize(delay: configuration.requestDelay) + (configuration.requestThrottling ? lastResponseTime : 0)
    }
    /// Retries map.
    private var retries: [URLEntry: Int] = [:]
    
    
    /** Initializes a new instance with given dependencies. */
    public init(configuration: RequestWorkerConfiguration,
         requestBuilder: RequestBuilderType,
         responseProcessor: ResponseInitialProcessingType,
         onFinished: @escaping FinishCallback)
    {
        self.configuration = configuration
        self.requestBuilder = requestBuilder
        self.responseProcessor = responseProcessor
        self.lives = configuration.maxNumberOfRequests
        self.onFinished = onFinished
    }
    
    // MARK: Public
    
    /** Starts processing a given URL entity. */
    public func startWorking(with entry: URLEntry, method: HTTPMethod = .get, body: RequestBodyType? = nil, parameters: JSON? = nil) {
        let delay = nextDelay
        Log.debug { Log.message("Starting worker with delay \(delay) for \(entry.urlString)") }
        startWorking(with: entry, method: method, body: body, parameters: parameters, delay: delay)
    }
    
    // MARK: Private
    
    private func createNetworkClient() -> NetworkClientType {
        // Create a URL session configuration
        let sessionConfig = URLSessionConfiguration.default
        if sessionConfig.httpAdditionalHeaders == nil {
            sessionConfig.httpAdditionalHeaders = [:]
        }
        // Set timout intervals
        sessionConfig.timeoutIntervalForRequest = configuration.requestTimeout
        sessionConfig.timeoutIntervalForResource = configuration.requestTimeout
        // Cookies settings
        sessionConfig.httpCookieAcceptPolicy = .always
        if let cookies = configuration.cookies {
            var headers = sessionConfig.httpAdditionalHeaders ?? [:]
            headers[HTTPHederFields.cookie.rawValue] = cookies
            sessionConfig.httpAdditionalHeaders = headers
        }
        // Proxy, if defined
        if let proxyConfiguration = configuration.proxy {
            sessionConfig.connectionProxyDictionary = createProxyDict(from: proxyConfiguration)
        }
        return NetworkClient(configuration: sessionConfig, delegate: self)
    }
    
    /** Create a proxy setting. */
    private func createProxyDict(from configuration: ProxyConfiguration) -> [AnyHashable: Any] {
        var dic: [AnyHashable: Any] = [:]
        // Setting all possible keys due to CF inconsistencies
        dic[kCFNetworkProxiesHTTPEnable] = 1
        dic[kCFNetworkProxiesHTTPProxy] = configuration.host
        dic[kCFNetworkProxiesHTTPPort] = configuration.port
        
        dic[kCFNetworkProxiesHTTPSEnable] = 1
        dic[kCFNetworkProxiesHTTPSProxy] = configuration.host
        dic[kCFNetworkProxiesHTTPSPort] = configuration.port
        
        dic[kCFProxyHostNameKey] = configuration.host
        dic[kCFProxyPortNumberKey] = configuration.port
        
        dic[kCFProxyUsernameKey] = configuration.username
        dic[kCFProxyPasswordKey] = configuration.password
        
        return dic
    }
    
    /** Request headers to use for requests. */
    private func createRequestHeaders() -> [String: String] {
        var headers: [String: String] = [:]
        if let agent = configuration.userAgents.randomElement() {
            headers[HTTPHederFields.userAgent.rawValue] = agent.header
        }
        if let referer = configuration.referers.randomElement() {
            headers[HTTPHederFields.referer.rawValue] = referer.header
        }
        return headers
    }
    
    /** Starts processing given entry. */
    private func startWorking(with entry: URLEntry, method: HTTPMethod = .get, body: RequestBodyType? = nil, parameters: JSON? = nil, delay: TimeInterval) {
        isRunning = true
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.download(with: entry, method: method, body: body, parameters: parameters)
        }
    }
    
    /** Starts downloading given entry. */
    private func download(with entry: URLEntry, method: HTTPMethod = .get, body: RequestBodyType? = nil, parameters: JSON? = nil) {
        // Build request
        guard let request = requestBuilder.buildRequest(method: method,
                                                        url: entry.urlString,
                                                        parameters: parameters,
                                                        body: body,
                                                        headers: createRequestHeaders())
            else {
                Log.error { Log.message("Could not build request!") }
                finish(with: .cancel, entry: entry, data: nil, response: nil, error: nil)
                return
        }
        // Create request task
        client.dataTask(with: request, serialization: ResponseSerialization.default) { [weak self] (result) in
            self?.process(result: result, for: request, entry: entry, method: method, body: body, parameters: parameters)
        }
        // Authentication (if needed)
        .onAuthenticationChallenge({ [weak self] (challenge) -> (URLSession.AuthChallengeDisposition, URLCredential?) in
            if let policy = self?.process(challenge: challenge) {
                return policy
            } else {
                return (.performDefaultHandling, nil)
            }
        })
        // Redirects
        .onHTTPRedirect({ (response, request) -> URLRequest? in
            // TODO: Redirect hook?
            if let fromURL = response.url?.absoluteString, let toURL = request.url?.absoluteString {
                Log.debug { Log.message("Did receive redirect from \(fromURL) to \(toURL)") }
            }
            return request
        })
        // Fire up the request
        .start()
        Log.info { Log.message("Fetching entry \(entry.urlString)") }
    }
    
    /** Processes a server response. */
    private func process(result: NetworkResult<Data>, for request: URLRequest, entry: URLEntry, method: HTTPMethod, body: RequestBodyType?, parameters: JSON?) {
        Log.debug { Log.message("Initial response processing for entry \(entry.urlString)") }
        // Get needed data
        let response: HTTPURLResponse?
        let responseData: Data?
        let networkError: NetworkError?
        switch result {
        case .success(value: let data, task: let task):
            response = task.response
            responseData = data
            networkError = nil
            lastResponseTime = task.metrics?.taskInterval.duration ?? 0
        case .failure(error: let error, task: let task, data: let data):
            response = task.response
            responseData = data
            networkError = error
            lastResponseTime = task.metrics?.taskInterval.duration ?? 0
        }
        // Initial response processing
        switch responseProcessor.process(request: request, result: result) {
        case .continue, .cancel, .die:
            // Hand over the results
            finish(with: .continue, entry: entry, data: responseData, response: response, error: networkError)
            // Decrease lives
            lives -= 1
        case .retry(after: let delay):
            let delay = delay ?? nextDelay
            // Try retry
            let tries = retries[entry] ?? 0
            if tries >= configuration.urlRetriesLimit {
                // Finish
                Log.debug { Log.message("A request worker died") }
                finish(with: .die, entry: entry, data: responseData, response: response, error: networkError)
            } else {
                // Retry
                Log.debug { Log.message("Will retry \(entry.urlString) after \(delay) seconds") }
                retries[entry] = tries + 1
                startWorking(with: entry, method: method, body: body, parameters: parameters, delay: delay)
            }
        }
    }
    
    /** Executes finifhing callback with given info. */
    private func finish(with result: ResponseProcessorResult, entry: URLEntry, data: Data?, response: HTTPURLResponse?, error: NetworkError?) {
        Log.info { Log.message("Finishing entry \(entry.urlString) with result \(result) response \(response?.statusCode ?? -1)") }
        // Clean up
        retries[entry] = nil
        // Other
        isRunning = false
        // Hand over the results
        onFinished(result, self, entry, data, response, error)
    }
    
}

extension RequestWorker: NetworkClientDelegate {
    
    public func networkClientDidFinishBackgroundEvents(_ client: NetworkClient) { /* no-op */ }
    
    public func networkClient(_ client: NetworkClient, didBecomeInvalidWithError error: Error?) {
        Log.error { Log.message("Network client became invalid! Error: \(String(describing: error))") }
        // Die
        lives = 0
    }
    
    public func networkCLient(_ client: NetworkClient, didReceive challenge: URLAuthenticationChallenge,
                       completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        let policy = process(challenge: challenge)
        completionHandler(policy.0, policy.1)
    }
    
    private func process(challenge: URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodDefault || challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic {
            // Check for provided authentication
            if let auth = configuration.authentication {
                let credential: URLCredential
                switch auth {
                case .usernamePassword(let username, let password):
                    credential = URLCredential(user: username, password: password, persistence: .forSession)
                    Log.info { Log.message("Received basic authentication challenge - authenticating with `\(username)` `\(password)`") }
                }
                return (.useCredential, credential)
            } else {
                // No authentication provided
                Log.warning { Log.message("Received basic authentication challenge but no authentication configured -> performing default handling. Challenge: \(challenge.protectionSpace.debugDescription)") }
            }
        }
        return (.performDefaultHandling, nil)
    }
    
}


extension RequestWorker: Hashable {
    
    public var hashValue: Int { return id.hashValue }
    
}

public func ==(lhs: RequestWorker, rhs: RequestWorker) -> Bool {
    return lhs.id == rhs.id
}
