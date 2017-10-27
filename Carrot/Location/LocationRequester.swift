//
//  LocationRequester.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/13/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - LocationRequester

public final class CarrotLocationRequester: NSObject, CLLocationManagerDelegate, LocationRequester {
  
  // MARK: Public
  
  public func fetch(result: @escaping (Result<CLLocation>) -> Void) {
    guard CLLocationManager.locationServicesEnabled() else {
      result(.error(LocationRequesterError.locationServicesNotAvailable))
      return
    }
    resultHandler = result
    locationManager.requestWhenInUseAuthorization()
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
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
  
  public func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation])
  {
    guard let location = locations.first else {
      resultHandler?(.error(LocationRequesterError.noLocationsFound))
      return
    }
    resultHandler?(.success(location))
  }
  
  public func locationManager(
    _ manager: CLLocationManager,
    didFailWithError error: Error)
  {
    resultHandler?(.error(error))
  }
}

// MARK: - LocationRequesterError

public enum LocationRequesterError: Error {
  case locationServicesNotAvailable
  case noLocationsFound
}

// MARK: - LocationRequester

public protocol LocationRequester {
 func fetch(result: @escaping (Result<CLLocation>) -> Void)
}
