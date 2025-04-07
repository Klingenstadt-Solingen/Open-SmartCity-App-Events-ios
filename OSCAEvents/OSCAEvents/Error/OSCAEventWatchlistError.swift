//
//  OSCAEventWatchlistError.swift
//  OSCAEvents
//
//  Created by Stephan Breidenbach on 14.02.22.
//

import Foundation

public enum OSCAEventWatchlistError: Swift.Error, CustomStringConvertible {
  case noEventID
  
  public var description: String {
    switch self {
    case .noEventID:
      return "There is no ID in the Event object!"
    }
  }// end war description
  
}// end public enum OSCAEventWatchlistError
