//
//  OSCAEventRepositoryTests.swift
//  OSCAEventsTests
//
//  Created by Stephan Breidenbach on 21.02.22.
//
#if canImport(XCTest) && canImport(OSCATestCaseExtension)
import XCTest
import Foundation
import Combine
@testable import OSCAEvents
import OSCANetworkService

class OSCAEventRepositoryTests: XCTestCase {
  private var cancellables            : Set<AnyCancellable>!
  private var eventStorage             : UserDefaultsEventStorage!
  private var eventRepository         : DefaultEventRepository!
  
  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    try super.setUpWithError()
    // init cancellables
    self.cancellables = []
    let userDefaults = try makeEventsTests().makeUserDefaults(domainString: "de.osca.events")
    let module = try makeEventsTests().makeDevModule()
    // init event storage
    self.eventStorage = UserDefaultsEventStorage(maxStorageLimit: 1000,
                                                 userDefaults: userDefaults)
    XCTAssertNotNil(self.eventStorage)
    // init event repository
    self.eventRepository = DefaultEventRepository(eventPersistantStorage: self.eventStorage,
                                                  module: module)
    XCTAssertNotNil(self.eventRepository)
  }// end override func setUpWithError
  
  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    if !self.cancellables.isEmpty {
      for cancellable in cancellables {
        cancellable.cancel()
      }// end for cancellable
    }// end if
    self.cancellables = []
  }// end override func tearDownWithError
  
  /// test the sequential download
  /// `publisher.prepend` functionality for prefixing datatasks
  func testDataTaskPublisher() throws {
    var publisher: AnyPublisher<(data: Data, response: URLResponse), Never> = Empty().eraseToAnyPublisher()
    
    XCTAssertNotNil(self.eventStorage)
    let urlStrings = [// extra small
      "http://ipv4.download.thinkbroadband.com/5MB.zip",
      // medium
      "http://ipv4.download.thinkbroadband.com/50MB.zip",
      // small
      "http://ipv4.download.thinkbroadband.com/10MB.zip"]
    // order of datatasks: [2,1,0]
    for urlString in urlStrings {
      // prepend
      publisher = publisher.prepend(dataTaskPublisher(urlString)).eraseToAnyPublisher()
    }// end for urlString
    var error: Error?
    var datas: [Data] = []
    // reserve capacity for 3 datas
    datas.reserveCapacity(3)
    let expectation = self.expectation(description: "data tasks fetch from network")
    expectation.expectedFulfillmentCount = 1
    
    publisher
      .sink(receiveCompletion: { completion in
        switch(completion) {
        case .finished:
          expectation.fulfill()
        case let .failure(encouteredError):
          error = encouteredError
          expectation.fulfill()
        }// end switch case
      }) { response in
        print("Data: \(response.data)\n \(response.response)")
        datas.append(response.data)
      }// end sink
      .store(in: &self.cancellables)
    waitForExpectations(timeout: 20)
    
    // There was NO error!
    XCTAssertNil(error)
    // there are exactly 3 downloaded data in datas
    XCTAssertTrue(datas.count == 3)
    // first downloaded data package < second downloaded data package
    XCTAssertTrue(datas[0].count < datas[1].count)
    // third downloaded data package < second downloaded data package
    XCTAssertTrue(datas[2].count < datas[1].count)
    // first downloaded data package < third downloaded data package
    XCTAssertTrue(datas[2].count < datas[0].count)
  }// end func testDataTaskPublisher
  
  
  private func dataTaskPublisher(_ urlString: String) -> AnyPublisher<(data: Data, response: URLResponse), Never> {
    let interceptedError = (Data(), URLResponse())
    return Just(URL(string: urlString)!)
      .flatMap {
        URLSession.shared
          .dataTaskPublisher(for: $0)
          .replaceError(with: interceptedError)
      }
      .eraseToAnyPublisher()
  }// end func dataTaskPublisher
}// end class OSCAEventRepositoryTests

extension OSCAEventRepositoryTests {
  
  public func makeEventsTests() -> OSCAEventsTests {
    let eventsTests = OSCAEventsTests()
    return eventsTests
  }// end public func makeEventsTests
}// end extension UserDefaultsEventWatchlistStorageTests
#endif
