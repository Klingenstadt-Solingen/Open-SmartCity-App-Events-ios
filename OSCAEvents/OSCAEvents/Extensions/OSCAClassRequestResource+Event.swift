//
//  OSCAClassRequestResource+Event.swift
//
//
//  Created by Stephan Breidenbach on 24.01.22.
//

import Foundation
import OSCANetworkService

extension OSCAClassRequestResource {
    /// `ClassReqestRessource` for legacy live event data
    ///```console
    /// curl -vX GET \
    /// -H "X-Parse-Application-Id: ApplicationId" \
    /// -H "X-PARSE-CLIENT-KEY: ClientKey" \
    /// -H 'Content-Type: application/json' \
    /// 'https://parse-dev.solingen.de/classes/LiveEvent'
    ///  ```
    /// - Parameters:
    ///   - baseURL: The base url of your parse-server
    ///   - headers: The authentication headers for parse-server
    ///   - query: HTTP query parameters for the request
    /// - Returns: A ready to use `OSCAClassRequestResource`
    @available(*, deprecated, message: "Use `OSCAClassRequestResource.event(baseURL,headers,query)` instead")
    static func liveEvent(baseURL: URL,
                          headers: [String: CustomStringConvertible],
                          query: [String: CustomStringConvertible] = [:]) -> OSCAClassRequestResource<OSCALiveEvent> {
        let parseClass = OSCALiveEvent.parseClassName
        return OSCAClassRequestResource<OSCALiveEvent>(baseURL: baseURL, parseClass: parseClass, parameters: query, headers: headers)
    }// end static func liveEvent
    
    /// `ClassRequestResource` for event data
    ///
    ///```console
    /// curl -vX GET \
    /// -H "X-Parse-Application-Id: ApplicationId" \
    /// -H "X-PARSE-CLIENT-KEY: ClientKey" \
    /// -H 'Content-Type: application/json' \
    /// 'https://parse-dev.solingen.de/classes/Event'
    ///  ```
    /// - Parameters:
    ///   - baseURL: The base url of your parse-server
    ///   - headers: The authentication headers for parse-server
    ///   - query: HTTP query parameters for the request
    /// - Returns: A ready to use `OSCAClassRequestResource`
    static func event(baseURL: URL,
                      headers: [String: CustomStringConvertible],
                      parameters: [String: CustomStringConvertible] = [:],
                      body: Data? = nil) -> OSCAClassRequestResource<OSCAEvent> {
        let parseClass = OSCAEvent.parseClassName
        return OSCAClassRequestResource<OSCAEvent>(baseURL: baseURL, parseClass: parseClass, parameters: parameters, headers: headers)
    }// end static func event
}// end extension public struct OSCAClassRequestResource
