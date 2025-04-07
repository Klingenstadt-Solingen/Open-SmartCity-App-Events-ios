//
//  UserDefaultsEventWatchlistStorageTests.swift
//  OSCAEventsTests
//
//  Created by Stephan Breidenbach on 14.02.22.
//
#if canImport(XCTest) && canImport(OSCATestCaseExtension)
import Foundation
import XCTest
import Combine
import OSCANetworkService
import OSCATestCaseExtension
@testable import OSCAEvents

final class UserDefaultsEventWatchlistStorageTests: XCTestCase {
  private enum UserDefaultsTestKeys: String {
    case eventWatchlistTestKey = "OSCAEventWatchlistTestKey"
  }// end private enum EventWatchlistUserDefaultsKey
  
  private var cancellables                : Set<AnyCancellable>!
  private var events                      : [OSCAEvent] = []
  private var eventWatchlist              : OSCAEventWatchlist?
  private var persistedEventWatchlist     : OSCAEventWatchlist?
  
  private var eventWatchlistStorage: UserDefaultsEventWatchlistStorage!
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    // init cancellables
    self.cancellables = []

    // init event watchlist storage
    self.eventWatchlistStorage = try UserDefaultsEventWatchlistStorage(maxStorageLimit: 2, userDefaults: makeEventsTests().makeUserDefaults(domainString: "de.osca.events"))
    XCTAssertNotNil(self.eventWatchlistStorage)
  }// end override func setuUpWithError
  
  func testFetchEventWatchlist() throws -> Void {
    // run test save event in watchlist
    try testSaveEventInWatchlist()
    // there are exact 3 events!
    XCTAssertEqual(self.events.count, 3)
    // there is an event watchlist
    XCTAssertNotNil(self.eventWatchlist)
    let eventWatchlist: OSCAEventWatchlist = self.eventWatchlist!
    
    var error: Error?
    
    let expectation = self.expectation(description: "Fetch Event from UserDefaults")
    
    self.eventWatchlistStorage.fetchEventWatchlist(maxCount: 2)
      .sink { completion in
        switch completion {
        case .finished:
          expectation.fulfill()
        case let .failure(encounteredError):
          error = encounteredError
          expectation.fulfill()
        }// end switch case
      }receiveValue: { watchlist in
        self.persistedEventWatchlist = watchlist
        // there are exactly 2 events in persisted event watchlist
        XCTAssertTrue(Set(watchlist.list).isSubset(of: Set(eventWatchlist.list)))
      }// end sink
      .store(in: &self.cancellables)
    waitForExpectations(timeout: 10)
    XCTAssertNil(error)
  }// end testFetchEventWatchlist
  
  func testSaveEventInWatchlist() throws -> Void  {
    // download and persist 3 events manually
    try downloadAndPersistEvents()
    // cancellables are initialized!
    XCTAssertNotNil(self.cancellables)
    // event watchlist storage exists!
    XCTAssertNotNil(self.eventWatchlistStorage)
    // get downloaded and persisted test event watchlist
    let eventWatchlistTest = try getPersistedEventWatchlistTest()
    // there are 3 persisted events in the test watchlist!
    XCTAssertEqual(eventWatchlistTest.list.count, 3)
    // there is a list of event and there are exact 3 in it
    XCTAssertEqual(self.events.count, 3)
    
    var error: [Error] = []
    let expectation = self.expectation(description: "Save Event to UserDefaults")
    expectation.expectedFulfillmentCount = 3
    // for event in downloaded events
    for event: OSCAEvent in self.events {
      // test save event in watchlist
      self.eventWatchlistStorage.saveEventInWatchlist(event: event)
        .sink{ completion in
          switch completion {
          case .finished:
            expectation.fulfill()
          case let .failure(encounteredError):
            error.append(encounteredError)
            expectation.fulfill()
          }// end switch case
        }receiveValue: { persistedEvent in
          XCTAssertEqual(event, persistedEvent)
        }// end sink
        .store(in: &self.cancellables)
    }
    waitForExpectations(timeout: 30)
    XCTAssertEqual(error.count, 0)
  }// end func testPersistEventWatchlist
  
  func testRemoveEventFromWatchlist() throws -> Void {
    // run test fetch event watchlist
    try testFetchEventWatchlist()
    // there are exactly 3 events in events
    XCTAssertEqual(self.events.count, 3)
    // remove an event, that is not in the watchlist
    XCTAssertFalse(self.eventWatchlistStorage.isEventOnWatchlist(event: self.events[0]))
    var error: [Error] = []
    let expectation = self.expectation(description: "Remove Event from UserDefaults")
    expectation.expectedFulfillmentCount = 2
    self.eventWatchlistStorage.removeEventFromWatchlist(event: self.events[0])
      .sink{ completion in
        switch completion {
        case .finished:
          expectation.fulfill()
        case let .failure(encounteredError):
          error.append(encounteredError)
          expectation.fulfill()
        }// end switch case
      }receiveValue: { _ in
        // the event is still not in the watchlist
        XCTAssertFalse(self.eventWatchlistStorage.isEventOnWatchlist(event: self.events[0]))
      }// end sink
      .store(in: &self.cancellables)
    
    // remove an event, that is in the watchlist
    XCTAssertTrue(self.eventWatchlistStorage.isEventOnWatchlist(event: self.events[1]))
    self.eventWatchlistStorage.removeEventFromWatchlist(event: self.events[1])
      .sink{ completion in
        switch completion {
        case .finished:
          expectation.fulfill()
        case let .failure(encounteredError):
          error.append(encounteredError)
          expectation.fulfill()
        }// end switch case
      }receiveValue: { _ in
        // the event is  not in the watchlist anymore
        XCTAssertFalse(self.eventWatchlistStorage.isEventOnWatchlist(event: self.events[1]))
      }// end sink
      .store(in: &self.cancellables)
    waitForExpectations(timeout: 10)
    XCTAssertEqual(error.count, 0)
  }// end func testRemoveEventFromWatchlist
  
  func testIsEventOnWatchlist() throws -> Void {
    // run test fetch event watchlist
    try testFetchEventWatchlist()
    // there are exactly 3 events in events
    XCTAssertEqual(self.events.count, 3)
    XCTAssertFalse(self.eventWatchlistStorage.isEventOnWatchlist(event: self.events[0]))
    XCTAssertTrue(self.eventWatchlistStorage.isEventOnWatchlist(event: self.events[1]))
    XCTAssertTrue(self.eventWatchlistStorage.isEventOnWatchlist(event: self.events[2]))
  }// end func testIsEventOnWatchlist
  
  private func downloadAndPersistEvents() throws -> Void {
    var error: Error?
    let expectation = self.expectation(description: "GetEventsFromNetwork")
    let module = try makeEventsTests().makeDevModule()
    let userDefaults = try makeEventsTests().makeUserDefaults(domainString: "de.osca.events")
    XCTAssertNotNil(module)
    module.getEvents(limit: 3)
      .sink{ completion in
        switch completion {
        case .finished:
          expectation.fulfill()
        case let .failure(encounteredError):
          error = encounteredError
          expectation.fulfill()
        }// end switch case
      } receiveValue: { result in
        switch result {
        case let .success(objects):
          self.events = objects
        case let .failure(encounteredError):
          error = encounteredError
        }// end switch result
      }// end sink
      .store(in: &self.cancellables)
    
    waitForExpectations(timeout: 10)
    // There is no error!
    XCTAssertNil(error)
    // There are exact 3 events!
    XCTAssertTrue(self.events.count == 3)
    // user default exist!
    XCTAssertNotNil(userDefaults)
    // persist data manually
    // construct event watchlist from downloaded events
    self.eventWatchlist =  OSCAEventWatchlist(self.events.compactMap {OSCAEventWatchItem.init(from: $0) })
    // encode event watchlist
    if let eventWatchlistData = try? JSONEncoder().encode(self.eventWatchlist) {
      // write event watchlist to user defaults
      userDefaults.set(eventWatchlistData, forKey: UserDefaultsTestKeys.eventWatchlistTestKey.rawValue)
    }// end if
    // read event watchlist from user defaults
    let eventWatchlistData = userDefaults.object(forKey: UserDefaultsTestKeys.eventWatchlistTestKey.rawValue) as? Data
    XCTAssertNotNil(eventWatchlistData)
    let eventWatchlistUserDefaults = try? JSONDecoder().decode(OSCAEventWatchlist.self, from: eventWatchlistData!)
    // event watchlist from user defaults is not nil
    XCTAssertNotNil(eventWatchlistUserDefaults)
    // event watchlist from user defaults count equals 3
    XCTAssertTrue(eventWatchlistUserDefaults!.list.count == 3)
    // event watchlist from user defaults equals event watchlist
    XCTAssertTrue(eventWatchlistUserDefaults == self.eventWatchlist)
  }// end private func downloadEvents
  
  private func getPersistedEventWatchlistTest() throws -> OSCAEventWatchlist {
    let userDefaults = try makeEventsTests().makeUserDefaults(domainString: "de.osca.events")
    let eventWatchlistTestObjectData = userDefaults.object(forKey: UserDefaultsTestKeys.eventWatchlistTestKey.rawValue) as? Data
    XCTAssertNotNil(eventWatchlistTestObjectData)
    let eventWatchlistTest = try? JSONDecoder().decode(OSCAEventWatchlist.self, from: eventWatchlistTestObjectData!)
    XCTAssertNotNil(eventWatchlistTest)
    return eventWatchlistTest!
  }// end private func getPersistedEventWatchlist
}// end final class UserDefaultsEventWatchlistStorageTests


extension UserDefaultsEventWatchlistStorageTests {
  
  public func makeEventsTests() -> OSCAEventsTests {
    let eventsTests = OSCAEventsTests()
    return eventsTests
  }// end public func makeEventsTests
}// end extension UserDefaultsEventWatchlistStorageTests
#endif
