//
//  PipelineRouter.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 14/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation



/**
 Class that manages pipelines.
 */
public class PipelineRouter {
    
    /** Shared router. */
    public static let shared = PipelineRouter()
    
    /** Whether any pipelies are running. */
    public var isRunning: Bool { return pipelines.filter({ $0.isRunning }).count > 0 }
    /** Registered pipelines. */
    public private(set) var pipelines = SynchronizedArray<PipelineType>()
    
    /** Registers given pipeline. */
    public func register(pipeline: PipelineType) {
        pipelines.append(pipeline)
    }
    
    /** Routes given server resposne and body data to available pipelines.  */
    public func route(response: HTTPURLResponse, data: Data, callback: @escaping (Result<Any>) -> Void) {
        for p in pipelines(for: response) {
            p.feed(response: response, data: data, callback: callback)
        }
    }
    
    // MARK: Private
    
    /** Filters appropriate pipelines for given response. Checks Content-Type and URL template. */
    private func pipelines(for response: HTTPURLResponse) -> [PipelineType] {
        guard let contentType = response.value(for: .contentType), let url = response.url?.absoluteString else { return [] }
        return pipelines.filter({ isContentType(contentType, andURL: url, validForContentType: $0.contentType, andURLRegex: $0.urlTemplate) })
    }
    
}

/** Helper function that compares given content types and URL with given URL template. */
public func isContentType(_ contentType: String, andURL url: String, validForContentType ctFilter: String?, andURLRegex urlRegex: String?) -> Bool {
    let ctFilter = ctFilter ?? "*/*"
    let urlRegex = urlRegex ?? ".*"
    // Check content types
    return isContentType(contentType, validForContentType: ctFilter) && url.matchesRegex(urlRegex)
}

/** Helper function that compares given content types. */
public func isContentType(_ contentType: String, validForContentType ctFilter: String) -> Bool {
    // Parse left
    guard let parsed = ContentTypeParser.parse(contentType) else {
        // Cannot parse content types -> compare raw string values
        return contentType == ctFilter
    }
    // Compare
    return parsed.matches(contentType: ctFilter)
}
