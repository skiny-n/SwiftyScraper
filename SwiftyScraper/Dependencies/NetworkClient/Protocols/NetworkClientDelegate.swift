//
//  NetworkClientDelegate.swift
//  Networking
//
//  Created by Stanislav Novacek on 22/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//


import Foundation

/**
 Network client delegate. Delegates session-related stuff.
 */
public protocol NetworkClientDelegate {
    
    /**
     If an application has received an -application:handleEventsForBackgroundURLSession:completionHandler:
     message, the session delegate will receive this message to indicate that all messages previously enqueued
     for this session have been delivered. At this time it is safe to invoke the previously stored completion
     handler, or to begin any internal updates that will result in invoking the completion handler.
     */
    func networkClientDidFinishBackgroundEvents(_ client: NetworkClient)
    
    /**
     The last message a session receives. A session will only become invalid because of a systemic error
     or when it has been explicitly invalidated, in which case the error parameter will be nil.
     */
    func networkClient(_ client: NetworkClient, didBecomeInvalidWithError error: Error?)
    
    /**
     If implemented, when a connection level authentication challenge has occurred, this delegate
     will be given the opportunity to provide authentication credentials to the underlying connection.
     Some types of authentication will apply to more than one request on a given connection to a server
     (SSL Server Trust challenges).  If this delegate message is not implemented, the behavior will be
     to use the default handling, which may involve user interaction.
     */
    func networkCLient(_ client: NetworkClient, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    
}
