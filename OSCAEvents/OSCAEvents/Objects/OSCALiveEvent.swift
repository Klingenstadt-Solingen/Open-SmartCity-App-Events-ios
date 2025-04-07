//
//  OSCALiveEvent.swift
//  
//
//  Created by Stephan Breidenbach on 24.01.22.
//

import Foundation
import OSCAEssentials

/**
 Event schema
 
 [see schema](https://git-dev.solingen.de/smartcityapp/documents/-/tree/master/X_Datastructure/1_Classes/schemas/ContactFormData.schema.json)
 - Parameter objectId: auto generated id
 - Parameter createdAt : UTC date when the object was created
 - Parameter updatedAt : UTC date when the object was changed
 - Parameter preis_zusatz            : ??
 - Parameter kostenlos               : ??
 - Parameter pretitle                : ??
 - Parameter foto                    : ??
 - Parameter section                 : ??
 - Parameter title                   : ??
 - Parameter subtitle                : ??
 - Parameter spende                  : ??
 - Parameter tickets                 : ??
 - Parameter artist                  : ??
 - Parameter ende                    : ??
 - Parameter name                    : ??
 - Parameter eventCancelMsg          : ??
 - Parameter info                    : ??
 - Parameter qrcode                  : ??
 - Parameter rubrikId                : ??
 - Parameter ort                     : ??
 - Parameter fotoThumb               : ??
 - Parameter highlight               : ??
 - Parameter label                   : ??
 - Parameter rubrik                  : ??
 - Parameter strasse                 : ??
 - Parameter vortId                  : ??
 - Parameter endDateTime             : ??
 - Parameter newEndDateTime          : ??
 - Parameter movedNr                 : ??
 - Parameter preise                  : ??
 - Parameter canceled                : ??
 - Parameter registration            : ??
 - Parameter soldout                 : ??
 - Parameter nachVereinbarung        : ??
 - Parameter link                    : ??
 - Parameter vort                    : ??
 - Parameter newStartDateTime        : ??
 - Parameter fotocredit              : ??
 - Parameter startDateTime           : ??
 - Parameter show                    : ??
 - Parameter movedOrt                : ??
 - Parameter geopoint                : ??
 - Parameter ganztags                : ??
 
 */
@available(*, deprecated, message: "Use `OSCAEvent` instead")
public struct OSCALiveEvent: Codable, Equatable, Hashable {
  public private(set) var objectId                : String?
  public private(set) var createdAt               : Date?
  public private(set) var updatedAt               : Date?
  public private(set) var preis_zusatz            : String?
  public private(set) var kostenlos               : String?
  public private(set) var pretitle                : String?
  public private(set) var foto                    : String?
  public private(set) var section                 : String?
  public private(set) var title                   : String?
  public private(set) var subtitle                : String?
  public private(set) var spende                  : String?
  public private(set) var tickets                 : String?
  public private(set) var artist                  : String?
  public private(set) var ende                    : String?
  public private(set) var name                    : String?
  public private(set) var eventCancelMsg          : String?
  public private(set) var info                    : String?
  public private(set) var qrcode                  : String?
  public private(set) var rubrikId                : String?
  public private(set) var ort                     : String?
  public private(set) var fotoThumb               : String?
  public private(set) var highlight               : String?
  public private(set) var label                   : String?
  public private(set) var rubrik                  : String?
  public private(set) var strasse                 : String?
  public private(set) var vortId                  : String?
  public private(set) var endDateTime             : Date?
  public private(set) var newEndDateTime          : Date?
  public private(set) var movedNr                 : String?
  public private(set) var preise                  : String?
  public private(set) var canceled                : String?
  public private(set) var registration            : String?
  public private(set) var soldout                 : String?
  public private(set) var nachVereinbarung        : String?
  public private(set) var link                    : String?
  public private(set) var vort                    : String?
  public private(set) var newStartDateTime        : Date?
  public private(set) var fotocredit              : String?
  public private(set) var startDateTime           : Date?
  public private(set) var show                    : String?
  public private(set) var movedOrt                : String?
  public private(set) var geopoint                : ParseGeoPoint?
  public private(set) var ganztags                : String?
}// end public struct OSCALiveEvent

@available(*, deprecated, message: "Use `OSCAEvent` instead")
extension OSCALiveEvent {
  /// Parse class name
  public static var parseClassName : String { return "CoworkingFormData" }
}// end extension OSCACoworkingFormData

@available(*, deprecated, message: "Use `OSCAEvent` instead")
extension OSCALiveEvent: OSCAParseClassObject {
  
}
