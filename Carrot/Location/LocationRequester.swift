//
//  LocationRequester.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/13/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - LocationRequestOptions

public struct LocationRequestOptions {
  public let desiredAccuracy: CLLocationAccuracy
  
  public init(desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest) {
    self.desiredAccuracy = desiredAccuracy
  }
}

extension LocationRequestOptions {
  public static var `default` = LocationRequestOptions()
}

// MARK: - LocationRequesterError

public enum LocationRequesterError: Error {
  case locationServicesNotAvailable
  case noLocationsFound
}

// MARK: - LocationRequester

public final class LocationRequester: NSObject, CLLocationManagerDelegate {
  
  // MARK: Public
  
  public func fetch(
    with options: LocationRequestOptions = .default,
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

extension CLLocation {
  public convenience init?(json: JSONDict) {
    guard let lat = json["lat"] as? CLLocationDegrees, let lon = json["lon"] as? CLLocationDegrees else {
      return nil
    }
    self.init(latitude: lat, longitude: lon)
  }
  
  public func data() throws -> Data {
    let json = ["lat": coordinate.latitude,
                "lon": coordinate.longitude]
    return try JSONSerialization.data(withJSONObject: json, options: [])
  }
}
