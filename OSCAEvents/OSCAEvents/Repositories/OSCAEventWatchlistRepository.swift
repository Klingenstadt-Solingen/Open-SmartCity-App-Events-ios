//
//  OSCAEventWatchlistRepository.swift
//  OSCAEvents
//
//  Created by Stephan Breidenbach on 14.02.22.
//

import Foundation
import Combine

public protocol OSCAEventWatchlistRepository {
  func fetchEventWatchlist(maxCount: Int) -> Future <OSCAEventWatchlist,OSCAEventWatchlistError>
  @available(*, deprecated, message: "Use `fetchEventWatchlist` instead")
  func fetchLiveEventWatchlist(maxCount: Int) -> Future<OSCALiveEventWatchlist, OSCAEventWatchlistError>
  func saveEventInWatchlist(event: OSCAEvent) -> Future<OSCAEvent, OSCAEventWatchlistError>
  @available(*, deprecated, message: "Use `saveEventInWatchlist` instead")
  func saveLiveEventInWatchlist(liveEvent: OSCALiveEvent) -> Future<OSCALiveEvent, OSCAEventWatchlistError>
  func removeEventFromWatchlist(event: OSCAEvent) -> Future<OSCAEventWatchlist, OSCAEventWatchlistError>
  @available(*, deprecated, message: "Use `removeEventFromWatchlist` instead")
  func removeLiveEventFromWatchlist(liveEvent: OSCALiveEvent) -> Future<OSCALiveEventWatchlist, OSCAEventWatchlistError> 
  func isEventOnWatchlist(event: OSCAEvent) -> Bool
  @available(*, deprecated, message: "Use `isEventOnWatchlist` instead")
  func isLiveEventOnWatchlist(liveEvent: OSCALiveEvent) -> Bool
}// end protocol OSCAEventWatchlistRepository

