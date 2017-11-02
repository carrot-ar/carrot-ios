//
//  BeaconRanger.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 11/1/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth

public final class BeaconRanger: NSObject {
  
  // MARK: Internal
  
  init(for region: CLBeaconRegion) {
    beaconRegion = region
  }
  
  deinit {
    locationManager.stopMonitoring(for: beaconRegion)
  }
  
  func startRanging(
    onError: @escaping (Error) -> Void,
    onImmediatePing: @escaping () -> Void)
  {
    if let error = error(for: CLLocationManager.authorizationStatus()) {
      onError(error)
      return
    }
    self.onError = onError
    self.onImmediatePing = onImmediatePing
    locationManager.requestWhenInUseAuthorization()
    locationManager.startMonitoring(for: beaconRegion)
    locationManager.startUpdatingLocation()
  }
  
  // MARK: Private
  
  private var onError: ((Error) -> Void)?
  private var onImmediatePing: (() -> Void)?
  private let beaconRegion: CLBeaconRegion
  
  private lazy var locationManager: CLLocationManager = {
    let manager = CLLocationManager()
    manager.delegate = self
    return manager
  }()
  
  private func error(for status: CLAuthorizationStatus) -> Error? {
    switch status {
    case .denied, .restricted:
      return BeaconRangerError.badStatus(status)
    case .notDetermined, .authorizedWhenInUse, .authorizedAlways:
      return nil
    }
  }
}

extension BeaconRanger: CLLocationManagerDelegate {
  
  public func locationManager(
    _ manager: CLLocationManager,
    didChangeAuthorization status: CLAuthorizationStatus)
  {
    if let error = error(for: status) {
      onError?(error)
    }
  }
  
  public func locationManager(
    _ manager: CLLocationManager,
    didStartMonitoringFor region: CLRegion)
  {
    locationManager.requestState(for: beaconRegion)
  }
  
  public func locationManager(
    _ manager: CLLocationManager,
    didDetermineState state: CLRegionState,
    for region: CLRegion)
  {
    switch state {
    case .inside:
      locationManager.startRangingBeacons(in: beaconRegion)
    case .outside:
      locationManager.stopRangingBeacons(in: beaconRegion)
    case .unknown:
      break
    }
  }
  
  public func locationManager(
    _ manager: CLLocationManager,
    didEnterRegion region: CLRegion)
  {
    print("Entered \(region)")
  }
  
  public func locationManager(
    _ manager: CLLocationManager,
    didExitRegion region: CLRegion)
  {
    print("Exited \(region)")
  }
  
  public func locationManager(
    _ manager: CLLocationManager,
    didRangeBeacons beacons: [CLBeacon],
    in region: CLBeaconRegion)
  {
    guard let beacon = beacons.first else { return }
    switch beacon.proximity {
    case .immediate:
      onImmediatePing?()
      manager.stopMonitoring(for: region)
      manager.stopUpdatingLocation()
    case .unknown, .far, .near:
      break
    }
  }
  
  public func locationManager(
    _ manager: CLLocationManager,
    didFailWithError error: Error)
  {
    onError?(error)
  }
  
  public func locationManager(
    _ manager: CLLocationManager,
    monitoringDidFailFor region: CLRegion?,
    withError error: Error)
  {
    onError?(error)
  }
}


enum BeaconRangerError: Error {
  case badStatus(CLAuthorizationStatus)
}
