//
//  OSCALiveEventWatchlist.swift
//  OSCAEvents
//
//  Created by Stephan Breidenbach on 14.02.22.
//

import Foundation

@available(*, deprecated, message: "Use `OSCAEventWatchlist` instead")
public struct OSCALiveEventWatchlist: Equatable, Codable, Hashable {
  var list: [OSCALiveEventWatchItem] = []
}// end struct OSCALiveEventWatchlist

// MARK: - OSCALiveEventWatchlist initializers
@available(*, deprecated, message: "Use `OSCAEventWatchlist` instead")
extension OSCALiveEventWatchlist {
  init(_ list: [OSCALiveEventWatchItem]) {
    self.list = list
  }// end init
}// extension struct OSCALiveEventWatchlist

@available(*, deprecated, message: "Use `OSCAEventWatchItem` instead")
struct OSCALiveEventWatchItem: Equatable, Codable, Hashable {
  let watchItem: String
}// end struct OSCALiveEventWatchItem

// MARK: - OSCALiveEventWatchItem initializers
@available(*, deprecated, message: "Use `OSCAEventWatchItem` instead")
extension OSCALiveEventWatchItem {
  init? (from liveEvent: OSCALiveEvent) {
    guard let liveEventId = liveEvent.objectId else { return nil }
    self.watchItem = liveEventId
  }// end init from OSCALiveEvent
}// end extension OSCALiveEventWatchItem


