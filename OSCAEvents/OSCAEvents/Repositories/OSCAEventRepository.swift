//
//  OSCAEventRepository.swift
//  OSCAEvents
//
//  Created by Stephan Breidenbach on 17.02.22.
//

import Foundation
import Combine
import OSCAEssentials

public protocol OSCAEventRepository {
  func fetchAllEvents(maxCount: Int, cachingStrategy: OSCARepository.OSCACachingStrategy) -> AnyPublisher<[OSCAEvent], OSCAEventError>
  func fetchTodaysEvents(maxCount: Int, cachingStrategy: OSCARepository.OSCACachingStrategy) -> AnyPublisher<[OSCAEvent], OSCAEventError>
  func fetchNextEvents(maxCount: Int, nextDays: Int, cachingStrategy: OSCARepository.OSCACachingStrategy) -> AnyPublisher<[OSCAEvent], OSCAEventError>
  func fetchEvents(maxCount:Int, with query: String, cachingStrategy: OSCARepository.OSCACachingStrategy) -> AnyPublisher<[OSCAEvent], OSCAEventError>
}// end public protocol OSCAEventRepository
