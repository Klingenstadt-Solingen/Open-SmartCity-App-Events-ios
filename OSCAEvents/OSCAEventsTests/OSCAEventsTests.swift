//
//  OSCAEventsTests.swift
//
//
//  Created by Stephan Breidenbach on 24.01.22.
//
#if canImport(XCTest) && canImport(OSCATestCaseExtension)
import XCTest
import Combine
import OSCAEssentials
import OSCANetworkService
import OSCATestCaseExtension

@_implementationOnly
import SwiftDate

@testable import OSCAEvents

final class OSCAEventsTests: XCTestCase {
  static let moduleVersion = "1.0.4"
  private var cancellables: Set<AnyCancellable>!
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    // initialize cancellables
    self.cancellables = []
  }// end override func setupWithError
  
  func testModuleInit() throws -> Void {
    // init module
    let module = try makeDevModule()
    XCTAssertNotNil(module)
    XCTAssertEqual(module.version, OSCAEventsTests.moduleVersion)
    XCTAssertEqual(module.bundlePrefix, "de.osca.events")
    // init bundle
    let bundle = OSCAEvents.bundle
    XCTAssertNotNil(bundle)
    XCTAssertNotNil(self.productionPlistDict)
    XCTAssertNotNil(self.devPlistDict)
  }// end func testModuleInit
  
  func testTransformError() throws -> Void {
    let module: OSCAEvents = try makeDevModule()
    XCTAssertEqual(module.transformError(OSCANetworkError.invalidResponse), OSCAEventError.networkInvalidResponse)
    XCTAssertEqual(module.transformError(OSCANetworkError.invalidRequest), OSCAEventError.networkInvalidRequest)
    let testData = Data([1,2,3])
    XCTAssertEqual(module.transformError(OSCANetworkError.dataLoadingError(statusCode: 1, data: testData)), OSCAEventError.networkDataLoading(statusCode: 1, data: testData))
    let error: Error = OSCAEventError.networkInvalidResponse
    XCTAssertEqual(module.transformError(OSCANetworkError.jsonDecodingError(error: error)), OSCAEventError.networkJSONDecoding(error: error))
    XCTAssertEqual(module.transformError(OSCANetworkError.isInternetConnectionError),OSCAEventError.networkIsInternetConnectionFailure)
  }// end func testTransformError
  
  func testDownloadEvent() throws -> Void {
    var events: [OSCAEvent] = []
    var error: Error?
    
    let expectation = self.expectation(description: "GetEvents")
    let module = try makeDevModule()
    module.getEvents(limit: 1)
      .sink { completion in
        switch completion {
        case .finished:
          expectation.fulfill()
        case let .failure(encounteredError):
          error = encounteredError
          expectation.fulfill()
        }// end switch completion
      } receiveValue: { result in
        switch result {
        case let .success(objects):
          events = objects
        case let .failure(encounteredError):
          error = encounteredError
        }// end switch result
      }// end sink
      .store(in: &self.cancellables)
    
    waitForExpectations(timeout: 10)
    
    XCTAssertNil(error)
    XCTAssertTrue(events.count == 1)
  } // end func testDownloadEvent
  
  func testFetchAllEvents() throws -> Void {
    var events: [OSCAEvent] = []
    var error: Error?
    
    let expectation = self.expectation(description: "fetchAllEvents")
    let module = try makeDevModule()
    module.fetchAllEvents(maxCount: 50)
      .sink { completion in
        switch completion {
        case .finished:
          expectation.fulfill()
        case let .failure(encounteredError):
          error = encounteredError
          expectation.fulfill()
        }// end switch completion
      } receiveValue: { allEventsFromNetwork in
        events = allEventsFromNetwork
      }// end sink
      .store(in: &self.cancellables)
    
    waitForExpectations(timeout: 10)
    
    XCTAssertNil(error)
    XCTAssertTrue(events.count == 50)
  } // end func testFetchAllEvents
  
  func testFetchAllEventsSortedBy() throws -> Void {
    var events: [OSCAEvent] = []
    var error: Error?
    
    let expectation = self.expectation(description: "fetchAllEventsSortedBy")
    let module = try makeDevModule()
    module.fetchAllEvents(maxCount: 50, sortedBy: OSCAEvents.sortInDecendingOrderByStartDatePredicate)
      .sink { completion in
        switch completion {
        case .finished:
          expectation.fulfill()
        case let .failure(encounteredError):
          error = encounteredError
          expectation.fulfill()
        }// end switch completion
      } receiveValue: { allEventsFromNetwork in
        events = allEventsFromNetwork
      }// end sink
      .store(in: &self.cancellables)
    
    waitForExpectations(timeout: 10)
    
    XCTAssertNil(error)
    XCTAssertTrue(events.count <= 50)
    XCTAssertTrue(checkStartDateDescendingOrder(on: events))
  } // end func testFetchAllEventsSortedBy
  
  func testFetchTodaysEvents() throws -> Void {
    var events: [OSCAEvent] = []
    var error: Error?
    
    let expectation = self.expectation(description: "fetchAllEvents")
    let module = try makeDevModule()
    module.fetchTodaysEvents(maxCount: 1000)
      .sink { completion in
        switch completion {
        case .finished:
          expectation.fulfill()
        case let .failure(encounteredError):
          error = encounteredError
          expectation.fulfill()
        }// end switch completion
      } receiveValue: { allEventsFromNetwork in
        events = allEventsFromNetwork
      }// end sink
      .store(in: &self.cancellables)
    
    waitForExpectations(timeout: 100)
    
    XCTAssertNil(error)
    if !events.isEmpty {
      XCTAssertTrue(checkTodaysEvents(on: events))
    }// end if
  } // end func testFetchTodaysEvents
  
  func testFetchNextEvents() throws -> Void {
    var events: [OSCAEvent] = []
    var error: Error?
    let nextDays = 2
    
    let expectation = self.expectation(description: "fetchAllEvents")
    let module = try makeDevModule()
    module.fetchNextEvents(maxCount: 1000, nextDays: nextDays)
      .sink { completion in
        switch completion {
        case .finished:
          expectation.fulfill()
        case let .failure(encounteredError):
          error = encounteredError
          expectation.fulfill()
        }// end switch completion
      } receiveValue: { allEventsFromNetwork in
        events = allEventsFromNetwork
      }// end sink
      .store(in: &self.cancellables)
    
    waitForExpectations(timeout: 100)
    
    XCTAssertNil(error)
    if !events.isEmpty {
      XCTAssertTrue(checkNextEvents(on: events, days: nextDays))
    }// end if
  } // end func testFetchNextEvents
  
  func testSlice() -> Void {
    // init test list
    var testList: [OSCAEvent] = []
    // set count to 2.000
    let count = 2000
    // radius days around today
    let radius = 30
    // set today
    let today = Date()
    /// populate test list with 20.000 `OSCAEvent` objects with `startDate` centered around today with an random radius of 30 days
    initOSCAEvents(around: today, radius: radius, count: count, list: &testList)
    // test list has count elements
    XCTAssertTrue(testList.count == count)
    // test list elements start date is in descending order!
    XCTAssertTrue(checkStartDateDescendingOrder(on: testList))
    // copy test list
    var slicedEvents: [OSCAEvent] = Array(testList)
    // slice test list from today plus radius / 2)
    // so the sliced range is subset of the test events range
    OSCAEvents.slice(for: today, plus: (radius / 2), in: &slicedEvents)
    // count of event which are in the range and are scheduled
    var estimatedCountOfEvents = countOSCAEvents(list: slicedEvents, where: rangeStartDate(date: today, plus: radius / 2))
    // sliced events are in descending order
    XCTAssertTrue(checkStartDateDescendingOrder(on: slicedEvents))
    // estimation accomplished
    XCTAssertTrue(slicedEvents.count == estimatedCountOfEvents)
    // copy test list
    slicedEvents = Array(testList)
    // slice test list from today plus 2 * radius
    // => so the upper range is greater than test events upper range
    OSCAEvents.slice(for: today, plus: 2 * radius, in: &slicedEvents)
    estimatedCountOfEvents = countOSCAEvents(list: slicedEvents, where: rangeStartDate(date: today, plus: 2 * radius))
    // sliced events are in descending order
    XCTAssertTrue(checkStartDateDescendingOrder(on: slicedEvents))
    // estimation accomplished
    XCTAssertTrue(slicedEvents.count == estimatedCountOfEvents)
  } // end testSlice
  
  func testFilterAllNotCancelledEvents() -> Void {
    // init test list
    var testList: [OSCAEvent] = []
    // set count to 2.000
    let count = 2000
    // radius days around today
    let radius = 30
    // set today
    let today = Date()
    /// populate test list with 20.000 `OSCAEvent` objects with `startDate` centered around today with an random radius of 30 days
    initOSCAEvents(around: today, radius: radius, count: count, list: &testList)
    // test list has count elements
    XCTAssertTrue(testList.count == count)
    // test list elements start date is in descending order!
    XCTAssertTrue(checkStartDateDescendingOrder(on: testList))
    // copy test list
    var filteredEvents = Array(testList)
    OSCAEvents.filterAllNotCancelledEvents(in: &filteredEvents)
    let estimatedCountOfEvents = countOSCAEvents(list: filteredEvents)
    XCTAssertTrue(filteredEvents.count == estimatedCountOfEvents)
  }// end testFilterAllNotCancelledEvents
  
  func testElasticSearchForEvents() throws -> Void {
    var events: [OSCAEvent]?
    let queryString = "Kino"
    var error: Error?
    
    let expectation = self.expectation(description: "elasticSearchForEvents")
    let module = try makeDevModule()
    module.elasticSearch(for: queryString)
      .sink { completion in
        switch completion {
        case .finished:
          expectation.fulfill()
        case let .failure(encounteredError):
          error = encounteredError
          expectation.fulfill()
        }// end switch case
      } receiveValue: { eventsFromNetwork in
        events = eventsFromNetwork
      }// end sink
      .store(in: &self.cancellables)
    
    waitForExpectations(timeout: 10)
    XCTAssertNil(error)
    XCTAssertNotNil(events)
    guard let events = events else {
      XCTFail("Elastic Search: No Hits for search \(queryString) "); return
    }// end guard
    XCTAssertTrue(!events.isEmpty)
  }// end func testElasticSearchForEvents
}// end final class OSCAEventsTests

// MARK: - factory methods
extension OSCAEventsTests {
  public func makeDevModuleDependencies() throws -> OSCAEventsDependencies {
    let networkService = try makeDevNetworkService()
    let userDefaults   = try makeUserDefaults(domainString: "de.osca.events")
    let dependencies = OSCAEventsDependencies(
      appStoreURL: nil, networkService: networkService,
      userDefaults: userDefaults,
      eventWatchlistMaxStorageLimit: 1000)
    return dependencies
  }// end public func makeDevModuleDependencies
  
  public func makeDevModule() throws -> OSCAEvents {
    let devDependencies = try makeDevModuleDependencies()
    // initialize module
    let module = OSCAEvents.create(with: devDependencies)
    return module
  }// end public func makeDevModule
  
  public func makeProductionModuleDependencies() throws -> OSCAEventsDependencies {
    let networkService = try makeProductionNetworkService()
    let userDefaults   = try makeUserDefaults(domainString: "de.osca.events")
    let dependencies = OSCAEventsDependencies(
      appStoreURL: nil, networkService: networkService,
      userDefaults: userDefaults,
      eventWatchlistMaxStorageLimit: 1000)
    return dependencies
  }// end public func makeProductionModuleDependencies
  
  public func makeProductionModule() throws -> OSCAEvents {
    let productionDependencies = try makeProductionModuleDependencies()
    // initialize module
    let module = OSCAEvents.create(with: productionDependencies)
    return module
  }// end public func makeProductionModule
}// end extension final class OSCAEventsTests

extension OSCAEventsTests {
  /// checks that `events` 's `startDate`is in descending order
  ///
  /// => latest events come first
  /// - Parameter on events:  list of events to be checked
  /// - Returns: `true` -> all event's `startDate`is ordered in an descending order
  private func checkStartDateDescendingOrder(on events: [OSCAEvent]) -> Bool {
    guard !events.isEmpty else { return false }
    if events.count == 1 { return true }
    for i in 1..<events.count {
      let lhs = events[i-1].startDate?.dateISO8601 ?? Date.distantPast
      let rhs = events[i].startDate?.dateISO8601 ?? Date.distantPast
      if lhs < rhs { return false }
    }// end for i
    return true
  }// end private func checkStartDateDescendingOrder
  
  /// checks that all events `startDate` is today
  /// - Parameter on events:  list of events to be checked
  /// - Returns: `true` -> all events start today
  private func checkTodaysEvents(on events: [OSCAEvent]) -> Bool {
    guard !events.isEmpty else { return false }
    let today = DateInRegion(Date(), region: Region.current)
    for event in events {
      guard let startDate = event.startDate?.dateISO8601 else { return false }
      let startDateRegion = DateInRegion(startDate, region: Region.current)
      let checkYear   = today.year == startDateRegion.year
      let checkMonth  = today.month == startDateRegion.month
      let checkDay    = today.day == startDateRegion.day
      let check       = checkYear && checkMonth && checkDay
      if !check { return false }
    }// end for event
    return true
  }// end private func checkTodaysEvents
  
  
  private func checkNextEvents(on events: [OSCAEvent], days: Int) -> Bool {
    guard !events.isEmpty else { return false }
    let today = Date()
    let todayBegin = DateInRegion(year: today.year, month: today.month, day: today.day, hour: 0, minute: 0, second: 0, region: Region.ISO)
    let nextEnd = DateInRegion(year: today.year, month: today.month, day: today.day+days+1, hour: 0, minute: 0, second: 0, region: Region.ISO)
    for event in events {
      guard let startDate = event.startDate?.dateISO8601 else { return false }
      let startDateRegion = DateInRegion(startDate, region: Region.ISO)
      let range = todayBegin..<nextEnd
      if !range.contains(startDateRegion) { return false }
    }// end for event
    return true
  }// end private func checkNextEvents
  
  /// initializes a `list` of `OSCAEvent`with random radius `days` around `seedDate`  for `startDate`,  and `count`amount of objects
  /// - Parameter around seedDate: the date around which the random days are centered
  /// - Parameter radius days: amount of days radius arount the seed date center >0
  /// - Parameter count: amount of `OSCAEvent`objects >0
  ///- Parameter list: array of `OSCAEvent`objects (`inout`), this list is ordered in descending order by `startDate`
  private func initOSCAEvents(around seedDate: Date, radius days: Int ,count: Int, list: inout [OSCAEvent]) -> Void {
    var initList: [OSCAEvent] = []
    guard count > 0 else {
      list = initList
      return
    }// end guard
    initList.reserveCapacity(count)
    
    let seedDateMilliseconds = seedDate.millisecondsSince1970
    
    guard seedDateMilliseconds > 0,
          days >= 0 else {
      list = initList
      return
    }// end guard
    // if the days radius is 0
    if days == 0 {
      // init list with startDate == seedDate
      // and random isCancelled status
      for _ in 0..<count {
        // init start Date from seedDateMilliseconds
        let startDate = Date(milliseconds: seedDateMilliseconds)
        // transform Date to ParseDate
        let parseDate = ParseDate(date: startDate)
        // event
        var event = OSCAEvent(startDate: parseDate)
        // init status
        let randomIsCancelled: Bool = Bool.random()
        event.eventStatus = randomIsCancelled ? OSCAEvent.Status.cancelled : OSCAEvent.Status.scheduled
        // append init list with event
        initList.append(event)
      }// end for
    }  else { // init list with random date radius around seedDate
      // transform radius days to milliseconds
      let daysInMilliseconds = Int64(24*60*60*1000*days)
      // Int64 range for the random radius
      let int64Range = Int64(0)..<daysInMilliseconds
      // init list with startDate with random days around centered seed date
      // and random isCancelled status
      for _ in 0..<count {
        // random + or -
        let randomSign: Bool = Bool.random()
        // Int64 random radius
        let radiusInt64 = Int64.random(in: int64Range)
        // init start Date
        let startDate: Date = randomSign ? Date(milliseconds: seedDateMilliseconds + radiusInt64) : Date(milliseconds: seedDateMilliseconds - radiusInt64)
        // transform Date to ParseDate
        let parseDate = ParseDate(date: startDate)
        // event
        var event = OSCAEvent(startDate: parseDate)
        // init status
        let randomIsCancelled: Bool = Bool.random()
        event.eventStatus = randomIsCancelled ? OSCAEvent.Status.cancelled : OSCAEvent.Status.scheduled
        // append init list with event
        initList.append(event)
      }// end for i
    }// end if
    // sort init list in descending order by startDate
    OSCAParse.sort(list: &initList, by: OSCAEvents.sortInDecendingOrderByStartDatePredicate)
    // set inout list to init list
    list = initList
    return
  }// end private func initOSCAEvents from to count
  
  private func rangeStartDate(date: Date, plus days: Int) -> ClosedRange<DateInRegion> {
    /// date begin is `date`at 00:00:00 am
    let dateBegin = DateInRegion(year: date.year, month: date.month, day: date.day, hour: 0, minute: 0, second: 0, region: Region.ISO)
    /// end date is `date`+ `days` at 23:59:59 pm
    let dateEnd = DateInRegion(year: date.year, month: date.month, day: date.day + days, hour: 23, minute: 59, second: 59, region: Region.ISO)
    return dateBegin...dateEnd
  }// end private func rangeStartDate
  
  /// counts all events which have a start date in range `where startDateInRange`
  /// - Parameter list: list of events
  /// - Parameter where startDateInRange: `DateInRegion` range
  private func countOSCAEvents(list: [OSCAEvent], where startDateInRange: ClosedRange<DateInRegion>) -> Int {
    guard list.count > 0 else { return 0 }
    var count = 0
    // iterate through list
    for event in list {
      // start date exists
      if let startDate = event.startDate,
         let startDateISO8601 = startDate.dateISO8601{
        // start date is in range
        let startDateInRegion = DateInRegion(startDateISO8601, region: Region.ISO)
        if startDateInRange.contains(startDateInRegion) {
          count += 1
        }// end if
      }// end if
    }// end for event
    return count
  }// end private func countOSCAEvnets where start date in range
  
  private func countOSCAEvents(list: [OSCAEvent], where status: OSCAEvent.Status = .scheduled ) -> Int {
    guard list.count > 0 else { return 0 }
    var count = 0
    for event in list {
      // status exists
      if let eventStatus = event.eventStatus,
         status == eventStatus {
        count += 1
      }// end if
    }// end for event
    return count
  }// end private func countOSCAEvents where status == .scheduled
}// end extension final class OSCAEventsTests
#endif
