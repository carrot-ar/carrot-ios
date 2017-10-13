//
//  Location.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/13/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - Location Options

public struct LocationOptions {
  let desiredAccuracy = kCLLocationAccuracyBest
}

// MARK: - Location

public final class Location {
  
  // MARK: Lifecycle
  
  init(
    options: LocationOptions = LocationOptions(),
    resultHandler: ((Result<CLLocation>) -> Void)? = nil)
  {
    self.options = options
    if let resultHandler = resultHandler {
      fetch(with: resultHandler)
    }
  }
  
  // MARK: Private
  
  private let options: LocationOptions
  
  public func fetch(with resultHandler: @escaping (Result<CLLocation>) -> Void) {
    LocationRequester.shared.fetch(
      with: options,
      resultHandler: resultHandler)
  }
}

// MARK: - LocationRequesterError

enum LocationRequesterError: Error {
  case locationServicesNotAvailable
  case noLocationsFound
}

// MARK: - LocationRequester

private final class LocationRequester: NSObject, CLLocationManagerDelegate {
  
  // MARK: Internal
  
  static let shared = LocationRequester()
  
  func fetch(
    with options: LocationOptions,
    resultHandler: @escaping (Result<CLLocation>) -> Void)
  {
    guard CLLocationManager.locationServicesEnabled() else {
      resultHandler(.error(LocationRequesterError.locationServicesNotAvailable))
      return
    }
    self.resultHandler = resultHandler
    locationManager.requestWhenInUseAuthorization()
    locationManager.desiredAccuracy = options.desiredAccuracy
    locationManager.requestLocation()
  }
  
  // MARK: Private
  
  private var resultHandler: ((Result<CLLocation>) -> Void)?
  
  private lazy var locationManager: CLLocationManager = {
    let manager = CLLocationManager()
    manager.delegate = self
    return manager
  }()
  
  // MARK: CLLocationManagerDelegate
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.first else {
      resultHandler?(.error(LocationRequesterError.noLocationsFound))
      return
    }
    resultHandler?(.success(location))
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    resultHandler?(.error(error))
  }
}
