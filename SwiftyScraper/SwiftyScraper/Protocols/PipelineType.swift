//
//  PipelineType.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 15/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/** Describes a pipeline. */
public protocol PipelineType {
    
    /** Whether or not the pipeline is running (processing data). */
    var isRunning: Bool { get }
    /** Content-Type this pipeline is able to parse. */
    var contentType: String? { get }
    /** URL template (regex) that this pipeline is able to handle. */
    var urlTemplate: String? { get }
    
    /**
     Feeds given response and data to the pipeline. Callback is called when the pipeline finishes.
     */
    func feed(response: HTTPURLResponse, data: Data, callback: ((Result<Any>) -> Void)?)
    
}
