//
//  OSCAEvent.swift
//
//
//  Created by Stephan Breidenbach on 09.02.22.
//
// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let oSCAEvent = try OSCAEventResult(json)

import Foundation
import OSCAEssentials
/**
 `OSCAEvent` schema
 [see schema](https://git-dev.solingen.de/smartcityapp/documents/-/blob/master/X_Datastructure/1_Classes/docs/event.md#event-type)
 */
public struct OSCAEvent: Equatable {
  // MARK: - Offers
  /**
   `OSCAEvent.Offers` schema
   [see schema](https://git-dev.solingen.de/smartcityapp/documents/-/blob/master/X_Datastructure/1_Classes/docs/event-properties-offers-offers.md)
   */
  public struct Offers: Codable, Equatable, Hashable {
    /**
     `OSCAEvent.Offers.AvailabilityType` schema
     [see schema](https://git-dev.solingen.de/smartcityapp/documents/-/blob/master/X_Datastructure/1_Classes/docs/event-properties-offers-offers.md#availability-type)
     */
    public enum AvailabilityType: String, Codable, Hashable {
      /// tickets are sold out
      case soldout             = "soldOut"
      /// tickets are available on pre sale
      case presale             = "preSale"
      /// tickets are available online only
      case onlineOnly          = "onlineOnly"
      /// tickets are only limited available
      case limitedAvailability = "limitedAvailability"
      /// tickets are only available in store
      case inStoreOnly         = "inStoreOnly"
      /// tickets are in stock
      case inStock             = "inStock"
    }// end public enum AvailablilityType
    
    /// the price of the ticket
    public var price           : String?
    /// the name of the offer
    public var name            : String?
    /// the currency for the price
    public var priceCurrency   : String? = "EUR"
    /// the availability of the offer
    public var availability    : AvailabilityType? = AvailabilityType.inStock
  }// end public struct Offers
  
  // MARK: - Address
  /**
   `OSCAEvent.Address` schema
   [see schema](https://git-dev.solingen.de/smartcityapp/documents/-/blob/master/X_Datastructure/1_Classes/docs/event-properties-location-properties-address.md)
   */
  public struct Address: Codable, Equatable, Hashable {
    /// The name of the event location
    public var name            : String?
    /// The street address of the event location
    public var streetAddress   : String?
    /// The locality of the event location
    public var addressLocality : String?
    /// The postal code of the event location
    public var postalCode      : String?
  }// end public struct Address
  
  // MARK: - Location
  /**
   `OSCAEvent.Location` schema
   [see schema](https://git-dev.solingen.de/smartcityapp/documents/-/blob/master/X_Datastructure/1_Classes/docs/event-properties-location.md)
   */
  public struct Location: Codable, Equatable, Hashable {
    /// The unique id of the event location
    public var id              : String?
    /// The address of the event location
    public var address         : Address?
    /// The geopoint of the event location
    public var geopoint        : ParseGeoPoint?
  }// end public struct Location
  
  // MARK: - Status
  /**
   `OSCAEvent.Status` schema
   [see schema](https://git-dev.solingen.de/smartcityapp/documents/-/blob/master/X_Datastructure/1_Classes/docs/event.md#eventstatus-type)
   */
  public enum Status: String, Codable, Hashable {
    /// event is scheduled
    case scheduled      = "scheduled"
    /// event is rescheduled
    case rescheduled    = "rescheduled"
    /// event is postponed
    case postponed      = "postponed"
    /// event is moved online
    case movedOnline    = "movedOnline"
    /// event is cancelled
    case cancelled      = "cancelled"
    
  }// end public enum Status
  
  // MARK: - AttendanceMode
  /**
   `OSCAEvent.AttendanceMode` schema
   [see schema](https://git-dev.solingen.de/smartcityapp/documents/-/blob/master/X_Datastructure/1_Classes/docs/event.md#eventattendancemode-type)
   */
  public enum AttendanceMode: String, Codable {
    /// event attendance mode online only
    case online     = "online"
    /// event attendance mode offline only
    case offline    = "offline"
    /// event attendance mode online and offline both
    case mixed      = "mixed"
  }// end public enum AttendanceMode
  
  /// Auto generated id
  public private(set) var objectId                        : String?
  /// UTC date when the object was created
  public private(set) var createdAt                       : Date?
  /// UTC date when the object was changed
  public private(set) var updatedAt                       : Date?
  /// The start date and time of the event (in ISO 8601 date format).
  public              var startDate                       : ParseDate?
  /// The end date and time of the event (in ISO 8601 date format).
  public              var endDate                         : ParseDate?
  /// The location of the event
  public              var location                        : Location?
  /// Offers and ticked information for the event
  public              var offers                          : [Offers]?
  /// Shows weather the event is all day or not
  public              var isAllDay                        : Bool?
  /// The name of the event
  public              var name                            : String?
  /// The description of the event
  public              var description                     : String?
  /// URL to the web version of the event.
  public              var url                             : String?
  /// The category of the event
  public              var category                        : String?
  /// The subcategory of the event
  public              var subcategory                     : String?
  /// An eventStatus of an event represents its status; particularly useful when an event is cancelled or rescheduled.
  public              var eventStatus                     : Status? = Status.scheduled
  /// URL to the source system
  public              var sourceUrl                       : String?
  /// The unique id of the event in the source system
  public              var sourceId                        : String?
  /// The eventAttendanceMode of an event indicates whether it occurs online, offline, or a mix.
  public              var eventAttendanceMode             : AttendanceMode? = AttendanceMode.offline
  /// The total number of individuals that may attend an event.
  public              var maximumAttendeeCapacity         : Int?
  /// The maximum physical attendee capacity of an Event whose eventAttendanceMode is online (or the online aspects, in the case of a mixed event)
  public              var maximumVirtualAttendeeCapacity  : Int?
  /// The previous date if the event is postponed
  public              var previousStartDate               : String?
  /// The typical expected age range
  public              var typicalAgeRange                 : String?
  /// The image of the event
  public              var image                           : String?
  /// Thumbnail image
  public              var thumbImage                      : String?
  /// Tags of the event. Could be used for elastic search or a detailed grouping.
  public              var tags                            : [String]?
}// end public struct OSCAEvent

extension OSCAEvent: OSCAParseClassObject {
  /// Parse class name
  public static var parseClassName : String { return "Event" }
}// end extension OSCAEvent
