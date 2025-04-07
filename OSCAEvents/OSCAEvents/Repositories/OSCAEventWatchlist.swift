//
//  OSCAEventWatchlist.swift
//  OSCAEvents
//
//  Created by Stephan Breidenbach on 14.02.22.
//

import Foundation

public struct OSCAEventWatchlist: Equatable, Codable, Hashable {
  public var list: [OSCAEventWatchItem] = []
}// end struct OSCAEventWatchlist

// MARK: - OSCAEventWatchlist initializers
extension OSCAEventWatchlist {
  init(_ list: [OSCAEventWatchItem]) {
    self.list = list
  }// end init
}// extension struct OSCAEventWatchlist

public struct OSCAEventWatchItem: Equatable, Codable, Hashable {
   public let watchItem: String
}// end struct OSCAEventWatchItem

// MARK: - OSCAEventWatchItem initializers
extension OSCAEventWatchItem {
  init? (from event: OSCAEvent) {
    guard let eventId = event.objectId else {
      return nil
    }
    self.watchItem = eventId
  }// end init from OSCAEvent
  
}// end extension OSCAEventWatchItem


