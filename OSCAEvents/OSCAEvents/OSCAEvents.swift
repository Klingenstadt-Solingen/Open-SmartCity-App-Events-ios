//
//  OSCAEvents.swift
//
//
//  Created by Stephan Breidenbach on 24.01.22.
//  reviewed by Stephan Breidenbach on 19.01.23
//

import Combine
import Foundation
import OSCAEssentials
import OSCANetworkService

@_implementationOnly
import SwiftDate

public struct OSCAEventsDependencies {
    let appStoreURL: URL?
    let networkService: OSCANetworkService
    let userDefaults: UserDefaults
    let eventWatchlistMaxStorageLimit: Int
    let analyticsModule: OSCAAnalyticsModule?
    
    public init(appStoreURL: URL?,
                networkService: OSCANetworkService,
                userDefaults: UserDefaults,
                eventWatchlistMaxStorageLimit: Int = 1000,
                analyticsModule: OSCAAnalyticsModule? = nil
    ) {
        self.appStoreURL = appStoreURL
        self.networkService = networkService
        self.userDefaults = userDefaults
        self.eventWatchlistMaxStorageLimit = eventWatchlistMaxStorageLimit
        self.analyticsModule = analyticsModule
    } // end public memberwise init
} // end public struct OSCAEventsDependencies

/// events module
public struct OSCAEvents: OSCAModule {
    /// module DI container
    var moduleDIContainer: OSCAEventsDIContainer!
    
    let transformError: (OSCANetworkError) -> OSCAEventError = { networkError in
        switch networkError {
        case OSCANetworkError.invalidResponse:
            return OSCAEventError.networkInvalidResponse
        case OSCANetworkError.invalidRequest:
            return OSCAEventError.networkInvalidRequest
        case let OSCANetworkError.dataLoadingError(statusCode: code, data: data):
            return OSCAEventError.networkDataLoading(statusCode: code, data: data)
        case let OSCANetworkError.jsonDecodingError(error: error):
            return OSCAEventError.networkJSONDecoding(error: error)
        case OSCANetworkError.isInternetConnectionError:
            return OSCAEventError.networkIsInternetConnectionFailure
        } // end switch case
    } // end let transformOSCANetworkErrorToOSCAEventError closure
    
    /// sort predicate for sort by event's start date in descending order
    ///
    /// => the latest event comes first
    public static let sortInDecendingOrderByStartDatePredicate: (OSCAEvent, OSCAEvent) -> Bool = {
        if let startDate0 = $0.startDate?.dateISO8601 {
            if let startDate1 = $1.startDate?.dateISO8601 {
                return startDate0 > startDate1
            }
            // $0 comes before $1
            return true
        } // end if
        if ($1.startDate?.dateISO8601) != nil {
            // $1 comes before $0
            return false
        } // end if
        // $0 comes before $1
        return true
    } // end public static let sortInDecendingOrderByStartDatePredicate
    
    /// version of the module
    public var version: String = "1.0.4"
    /// bundle prefix of the module
    public var bundlePrefix: String = "de.osca.events"
    
    /// module `Bundle`
    ///
    /// **available after module initialization only!!!**
    public internal(set) static var bundle: Bundle!
    
    public internal(set) var appStoreURL: URL?
    
    /// network service
    private var networkService: OSCANetworkService
    
    public private(set) var userDefaults: UserDefaults
    
    /// repository for event watchlist conforming to `OSCAEventWatchlistRepository` protocol
    public var eventWatchlistRepository: OSCAEventWatchlistRepository!
    
    /**
     create module and inject module dependencies
     
     ** This is the only way to initialize the module!!! **
     - Parameter moduleDependencies: module dependencies
     ```
     call: OSCAEvents.create(with moduleDependencies)
     ```
     */
    public static func create(with moduleDependencies: OSCAEventsDependencies) -> OSCAEvents {
        var module: Self = Self(appStoreURL: moduleDependencies.appStoreURL, networkService: moduleDependencies.networkService,
                                userDefaults: moduleDependencies.userDefaults)
        module.moduleDIContainer = OSCAEventsDIContainer(dependencies: moduleDependencies)
        module.appStoreURL = moduleDependencies.appStoreURL
        return module
    } // end public static func create
    
    /// initializes the events module
    ///  - Parameter networkService: Your configured network service
    private init(appStoreURL: URL? = nil,
                 networkService: OSCANetworkService,
                 userDefaults: UserDefaults) {
        self.appStoreURL = appStoreURL
        self.networkService = networkService
        self.userDefaults = userDefaults
        var bundle: Bundle?
#if SWIFT_PACKAGE
        bundle = Bundle.module
#else
        bundle = Bundle(identifier: bundlePrefix)
#endif
        guard let bundle: Bundle = bundle else { fatalError("Module bundle not initialized!") }
        Self.bundle = bundle
    }
}

// - MARK: fetch all events and mutate locally
extension OSCAEvents {
    public typealias OSCAEventsPublisher = AnyPublisher<[OSCAEvent], OSCAEventError>
    
    public func fetchSingularEvent(objectId: String) -> AnyPublisher<[OSCAEvent], OSCANetworkError> {
        var parameters: [String: String] = [:]
        parameters["limit"] = "1"
        parameters["where"] = "{\"objectId\":\"\(objectId)\"}"
        
        var headers = networkService.config.headers
        if let sessionToken = userDefaults.string(forKey: "SessionToken") {
            headers["X-Parse-Session-Token"] = sessionToken
        }
        
        return networkService.fetch(OSCAClassRequestResource<OSCAEvent>
            .event(baseURL: networkService.config.baseURL,
                   headers: headers,
                   parameters: parameters))
        .subscribe(on: OSCAScheduler.backgroundWorkScheduler)
        .eraseToAnyPublisher()
    }
    
    public func fetchParseEvents(limit: Int = 20, skip: Int = 0) -> AnyPublisher<[OSCAEvent], OSCANetworkError> {
        guard limit > 0 else {
            return Empty(completeImmediately: true).eraseToAnyPublisher()
        }
        var parameters: [String: String] = [:]
        parameters["limit"] = "\(limit)"
        parameters["skip"] = "\(skip)"
        parameters["order"] = "startDate"
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let startDateString =  formatter.string(from: Calendar.current.startOfDay(for: Date.now))
        parameters["where"] = "{\"startDate\":{\"$gte\":\"\(startDateString)\"}}"
        
        var headers = networkService.config.headers
        if let sessionToken = userDefaults.string(forKey: "SessionToken") {
            headers["X-Parse-Session-Token"] = sessionToken
        }
        
        return networkService.fetch(OSCAClassRequestResource<OSCAEvent>
            .event(baseURL: networkService.config.baseURL,
                   headers: headers,
                   parameters: parameters))
        .subscribe(on: OSCAScheduler.backgroundWorkScheduler)
        .eraseToAnyPublisher()
    }
    
    public func fetchParseEventCount() -> AnyPublisher<Int?, OSCANetworkError> {
        var parameters: [String: String] = [:]
        parameters["limit"] = "0"
        parameters["count"] = "1"
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let startDateString =  formatter.string(from: Calendar.current.startOfDay(for: Date.now))
        let endDateString = formatter.string(from: Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date.now)!))
        parameters["where"] = "{\"$or\":[{\"endDate\":{\"$exists\":false},\"startDate\":{\"$gte\":\"\(startDateString)\",\"$lte\":\"\(endDateString)\"}},{\"endDate\":{\"$gte\":\"\(startDateString)\"},\"startDate\":{\"$lte\":\"\(endDateString)\"}}]}"
        
        var headers = networkService.config.headers
        if let sessionToken = userDefaults.string(forKey: "SessionToken") {
            headers["X-Parse-Session-Token"] = sessionToken
        }
        return count(OSCAClassRequestResource<OSCAEvent>
            .event(baseURL: networkService.config.baseURL,
                   headers: headers,
                   parameters: parameters)).subscribe(on: OSCAScheduler.backgroundWorkScheduler)
            .eraseToAnyPublisher()
    }
    
    public func fetchElasticEvents(limit: Int = 20, skip: Int = 0, date: Date?, bookmarkedIds: [String]? = nil, query: String, index: String = "events", isRaw: Bool = false) -> OSCAEventsPublisher {
        var startDateString: String? = nil
        var endDateString: String? = nil
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            let startDate =  Calendar.current.startOfDay(for: date)
            var components = DateComponents()
            components.day = 1
            components.second = -1
            let endDate = Calendar.current.date(byAdding: components, to: startDate)
            startDateString = formatter.string(from: startDate)
            if let endDate = endDate {
                endDateString = formatter.string(from: endDate)
            }
        }
        
        let cloudFunctionParameter = EventElasticParameters(index: index,
                                                            query: query,
                                                            from: skip,
                                                            size: limit,
                                                            startDateIso: startDateString,
                                                            endDateIso: endDateString,
                                                            objectIds: bookmarkedIds,
                                                            raw: isRaw)
        
        var publisher: AnyPublisher<[OSCAEvent], OSCANetworkError>
        
        var headers = networkService.config.headers
        if let sessionToken = userDefaults.string(forKey: "SessionToken") {
            headers["X-Parse-Session-Token"] = sessionToken
        }
        
        publisher = networkService.fetch(OSCAFunctionRequestResource<ParseElasticSearchQuery>
            .eventElasticSearch(baseURL: networkService.config.baseURL,
                                headers: headers,
                                cloudFunctionParameter: cloudFunctionParameter))
        return publisher
            .mapError(transformError)
            .subscribe(on: OSCAScheduler.backgroundWorkScheduler)
            .eraseToAnyPublisher()
    }
    
    public func fetchElasticEventsCount(date: Date?, bookmarkedIds: [String]? = nil, query: String, index: String = "events", isRaw: Bool = false) -> AnyPublisher<Int?, OSCANetworkError> {
        var startDateString: String? = nil
        var endDateString: String? = nil
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            let startDate =  Calendar.current.startOfDay(for: date)
            var components = DateComponents()
            components.day = 1
            components.second = -1
            let endDate = Calendar.current.date(byAdding: components, to: startDate)
            startDateString = formatter.string(from: startDate)
            if let endDate = endDate {
                endDateString = formatter.string(from: endDate)
            }
        }
        
        let cloudFunctionParameter = EventElasticCountParameters(index: index,
                                                                 query: query,
                                                                 startDateIso: startDateString,
                                                                 endDateIso: endDateString,
                                                                 objectIds: bookmarkedIds,
                                                                 raw: isRaw)
        var headers = networkService.config.headers
        if let sessionToken = userDefaults.string(forKey: "SessionToken") {
            headers["X-Parse-Session-Token"] = sessionToken
        }
        
        return count(OSCAFunctionRequestResource<ParseElasticSearchQuery>
            .eventElasticSearchCount(baseURL: networkService.config.baseURL,
                                     headers: headers,
                                     cloudFunctionParameter: cloudFunctionParameter))
        .subscribe(on: OSCAScheduler.backgroundWorkScheduler)
        .eraseToAnyPublisher()
    }
    
    // CUSTOM COUNT REQUEST
    @discardableResult
    public func count<Request>(_ resource: Request) -> AnyPublisher<Int?, OSCANetworkError> where Request: OSCAClassRequestResourceProtocol {
        guard let request = resource.requestClass else {
            return Fail.init(outputType: Int?.self, failure: OSCANetworkError.invalidRequest).eraseToAnyPublisher()
        }
        
        return networkService.config.session.dataTaskPublisher(for: request)
            .mapError { (error: URLError) -> OSCANetworkError in
                if error.isInternetConnectionError {
                    return OSCANetworkError.isInternetConnectionError
                } else {
                    return OSCANetworkError.invalidRequest
                }
            }
            .flatMap {  data, response -> AnyPublisher<Data, OSCANetworkError> in
                guard let response = response as? HTTPURLResponse
                else {
                    return .fail(OSCANetworkError.invalidResponse)
                }
                
                guard 200 ..< 300 ~= response.statusCode
                else {
                    return .fail(OSCANetworkError.dataLoadingError(statusCode: response.statusCode, data: data))
                }
                return .just(data)
            }
            .eraseToAnyPublisher()
            .flatMap { data -> AnyPublisher<Int?, OSCANetworkError> in
                var queryResponse: CountResponse?
                do {
                    queryResponse = try OSCACoding.jsonDecoder().decode(CountResponse.self, from: data)
                } catch {
                    return Fail.init(outputType: Int?.self, failure:
                                        OSCANetworkError.jsonDecodingError(error: error))
                    .eraseToAnyPublisher()
                }
                guard let queryResponse = queryResponse else {
                    return Fail.init(outputType: Int?.self, failure: OSCANetworkError.invalidResponse)
                        .eraseToAnyPublisher()
                }
                return Just(queryResponse.count)
                    .setFailureType(to: OSCANetworkError.self)
                    .eraseToAnyPublisher()
                
            }
            .eraseToAnyPublisher()
    }
    
    // CUSTOM ELASTIC COUNT REQUEST
    @discardableResult
    public func count<Request>(_ resource: Request) -> AnyPublisher<Int?, OSCANetworkError> where Request: OSCAFunctionRequestResourceProtocol {
        guard let request = resource.requestFunction else {
            return Fail.init(outputType: Int?.self, failure: OSCANetworkError.invalidRequest).eraseToAnyPublisher()
        }
        guard let request = resource.requestFunction else {
            return Fail.init(outputType: Int?.self, failure: OSCANetworkError.invalidRequest).eraseToAnyPublisher()
        }
        
        return networkService.config.session.dataTaskPublisher(for: request)
            .mapError { (error: URLError) -> OSCANetworkError in
                if error.isInternetConnectionError {
                    return OSCANetworkError.isInternetConnectionError
                } else {
                    return OSCANetworkError.invalidRequest
                }
            }
            .flatMap { data, response -> AnyPublisher<Data, OSCANetworkError> in
                guard let response = response as? HTTPURLResponse
                else {
                    return .fail(OSCANetworkError.invalidResponse)
                }
                
                guard 200 ..< 300 ~= response.statusCode
                else {
                    return .fail(OSCANetworkError.dataLoadingError(statusCode: response.statusCode, data: data))
                }
                
                return .just(data) }
            .eraseToAnyPublisher()
            .flatMap { data -> AnyPublisher<Int?, OSCANetworkError> in
                var functionResponse: ElasticCountResponse?
                do {
                    functionResponse = try OSCACoding.jsonDecoder().decode(ElasticCountResponse.self, from: data)
                }  catch {
#if DEBUG
                    print("error: ", error)
#endif
                    return Fail.init(outputType: Int?.self, failure:
                                        OSCANetworkError.jsonDecodingError(error: error))
                    .eraseToAnyPublisher()
                }
                guard let functionResponse = functionResponse else {
                    return Fail.init(outputType: Int?.self, failure: OSCANetworkError.invalidResponse)
                        .eraseToAnyPublisher()
                }

                return Just(functionResponse.result?.count)
                    .setFailureType(to: OSCANetworkError.self)
                    .eraseToAnyPublisher()
                
            }
            .eraseToAnyPublisher()
    }
}

extension OSCAFunctionRequestResource {
    public static func eventElasticSearch(baseURL: URL,
                                          headers: [String: CustomStringConvertible],
                                          cloudFunctionParameter: EventElasticParameters) -> OSCAFunctionRequestResource<EventElasticParameters> {
        let cloudFunctionName = "elastic-search"
        return OSCAFunctionRequestResource<EventElasticParameters>(baseURL: baseURL, cloudFunctionName: cloudFunctionName, cloudFunctionParameter: cloudFunctionParameter, headers: headers)
    }
}


// custom parameters for elastic
public struct EventElasticParameters {
    public var index: String?
    public var query: String?
    public var from: Int
    public var size: Int
    public var startDateIso: String?
    public var endDateIso: String?
    public var objectIds: [String]?
    public var raw: Bool
}

extension EventElasticParameters {
    public init( index: String,
                 query: String,
                 from: Int,
                 size: Int,
                 startDateIso: String? = nil,
                 endDateIso: String? = nil,
                 objectIds: [String]? = nil,
                 raw  : Bool = true
    ) {
        self.index = index
        self.query = query
        self.from = from
        self.size = size
        self.startDateIso = startDateIso
        self.endDateIso = endDateIso
        self.objectIds = objectIds
        self.raw   = raw
    }
}

extension EventElasticParameters: Codable {}
extension EventElasticParameters: Hashable {}
extension EventElasticParameters: Equatable {}

struct CountResponse: Decodable {
    let count: Int?
}

struct ElasticCountResponse: Decodable {
    let result: CountResponse?
}

extension OSCAFunctionRequestResource {
    public static func eventElasticSearchCount(baseURL: URL,
                                               headers: [String: CustomStringConvertible],
                                               cloudFunctionParameter: EventElasticCountParameters) -> OSCAFunctionRequestResource<EventElasticCountParameters> {
        let cloudFunctionName = "elastic-search-count"
        return OSCAFunctionRequestResource<EventElasticCountParameters>(baseURL: baseURL, cloudFunctionName: cloudFunctionName, cloudFunctionParameter: cloudFunctionParameter, headers: headers)
    }
}


// custom parameters for elastic
public struct EventElasticCountParameters {
    public var index: String?
    public var query: String?
    public var startDateIso: String?
    public var endDateIso: String?
    public var objectIds: [String]?
    public var raw: Bool
}

extension EventElasticCountParameters {
    public init( index: String,
                 query: String,
                 startDateIso: String? = nil,
                 endDateIso: String? = nil,
                 objectIds: [String]? = nil,
                 raw  : Bool = true
    ) {
        self.index = index
        self.query = query
        self.startDateIso = startDateIso
        self.endDateIso = endDateIso
        self.objectIds = objectIds
        self.raw   = raw
    }
}

extension EventElasticCountParameters: Codable {}
extension EventElasticCountParameters: Hashable {}
extension EventElasticCountParameters: Equatable {}
