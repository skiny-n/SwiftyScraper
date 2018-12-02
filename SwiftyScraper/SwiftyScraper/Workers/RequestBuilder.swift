//
//  RequestBuilder.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 13/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/**
 Class responsible for building HTTP requests.
 */
open class RequestBuilder {
    
    /** Default headers to use for requests. */
    open var defaultHeaders: [String: String] {
        return[
            HTTPHederFields.accept.rawValue: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            HTTPHederFields.acceptCharset.rawValue: "utf-8",
            HTTPHederFields.acceptEncoding.rawValue: "br, gzip, deflate",
            HTTPHederFields.acceptLanguage.rawValue: "en-us"
        ]
    }
    
}

extension RequestBuilder: RequestBuilderType {
    
    /** Creates an HTTP request with given method, URL, parameters, body and headers. */
    open func buildRequest(method: HTTPMethod, url: String,
                           parameters: JSON? = nil, body: RequestBodyType? = nil,
                           headers: [String: String] = [:]) -> URLRequest?
    {
        // URL components
        guard var urlComponents = URLComponents(string: url) else {
            Log.error { Log.message("Could not build request - invalid URL \(url)") }
            return nil
        }
        // URL parameters
        if let parameters = parameters, parameters.keys.count > 0 {
            var items = urlComponents.queryItems ?? []
            items.append(contentsOf: parameters.map({
                URLQueryItem(name: $0.key, value: "\($0.value)")
            }))
            urlComponents.queryItems = items.count > 0 ? items : nil
        }
        // URL
        guard let url = urlComponents.url else {
            Log.error { Log.message("Could not build request - cannot construct URL from \(urlComponents)") }
            return nil
        }
        // Request
        var request = URLRequest(url: url)
        // Method
        request.httpMethod = method.rawValue
        // Headers
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        // Body
        if let body = body {
            switch body {
            case .url(let params): RequestBuilder.encode(urlBody: params, into: &request)
            case .json(let json): RequestBuilder.encode(jsonBody: json, into: &request)
            case .xml(let xml): RequestBuilder.encode(xmlBody: xml, into: &request)
            }
        }
        // Done
        return request
    }
    
}

public extension RequestBuilder {
    
    /** Randomizes deley - multiplies with a random perc. */
    static func randomize(delay: TimeInterval) -> TimeInterval {
        let percs: [Double] = [0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1.0, 1.05, 1.1, 1.15, 1.20, 1.25, 1.3, 1.35]
        var randomized = percs.randomElement()! * delay * percs.randomElement()!
        if randomized < 3 {
            randomized += 2
        }
        return randomized
    }
    
    /** Creates a URL query from given parameters. */
    static func createURLQuery(from params: JSON) -> String? {
        var components = URLComponents()
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        return components.query
    }
    
    /** Sets URL encoded body (and Content-Type header if needed) into given request. */
    static func encode(urlBody body: JSON, into request: inout URLRequest) {
        if let data = createURLQuery(from: body)?.data(using: .utf8) {
            request.httpBody = data
            if request.value(for: .contentType) == nil {
                request.set("application/x-www-form-urlencoded; charset=utf-8", for: .contentType)
            }
        } else {
            let requestDescription = request.description
            Log.error { Log.message("Could not encode URL body: \(body) into request: \(requestDescription)") }
        }
    }
    
    /** Sets JSON encoded body (and Content-Type header if needed) into given request. */
    static func encode(jsonBody body: JSON, into request: inout URLRequest) {
        do {
            let data = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = data
            if request.value(for: .contentType) == nil {
                request.set("application/json; charset=utf-8", for: .contentType)
            }
        } catch {
            let requestDescription = request.description
            Log.error { Log.message("Could not encode JSON body: \(body) into request: \(requestDescription). Error: \(error)") }
        }
    }
    
    /** Sets XML encoded body (and Content-Type header if needed) into given request. */
    static func encode(xmlBody body: String, into request: inout URLRequest) {
        if let body = body.data(using: .utf8) {
            request.httpBody = body
            if request.value(for: .contentType) == nil {
                request.set("application/xml; charset=utf-8", for: .contentType)
            }
        } else {
            let requestDescription = request.description
            Log.error { Log.message("Could not encode XML body: \(body) into request: \(requestDescription)") }
        }
    }
    
}
