//
//  BeaconRanger.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 11/1/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation
import CoreLocation

public final class BeaconRanger: NSObject {
  
  // MARK: Internal
  
  public init(for region: CLBeaconRegion) {
    beaconRegion = region
    beaconRegion.notifyEntryStateOnDisplay = true
  }
  
  deinit {
    stopMonitoring()
  }
  
  // MARK: Public
  
  public func startMonitoring(
    onProximityChange: @escaping (BeaconRanger, CLProximity) -> Void,
    onError: @escaping (Error) -> Void)
  {
    if let error = error(for: CLLocationManager.authorizationStatus()) {
      onError(error)
      return
    }
    if let error = error(for: UIApplication.shared.backgroundRefreshStatus) {
      onError(error)
      return
    }
    self.onProximityChange = onProximityChange
    self.onError = onError
    locationManager.requestAlwaysAuthorization()
    locationManager.startMonitoring(for: beaconRegion)
  }
  
  public func stopMonitoring() {
    locationManager.stopRangingBeacons(in: beaconRegion)
    locationManager.stopMonitoring(for: beaconRegion)
  }
  
  // MARK: Private
  
  private var onProximityChange: ((BeaconRanger, CLProximity) -> Void)?
  private var onError: ((Error) -> Void)?
  private let beaconRegion: CLBeaconRegion
  
  private lazy var locationManager: CLLocationManager = {
    let manager = CLLocationManager()
    manager.delegate = self
    return manager
  }()
  
  private func error(for status: CLAuthorizationStatus) -> Error? {
    switch status {
    case .restricted:
      return BeaconRangerError.locationRestricted
    case .denied:
      return BeaconRangerError.locationDenied
    case .notDetermined, .authorizedWhenInUse, .authorizedAlways:
      return nil
    }
  }
  
  private func error(for status: UIBackgroundRefreshStatus) -> Error? {
    switch status {
    case .restricted:
      return BeaconRangerError.backgroundRefreshRestricted
    case .denied:
      return BeaconRangerError.backgroundRefreshDenied
    case .available:
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
      return
    }
  }
  
  public func locationManager(
    _ manager: CLLocationManager,
    didDetermineState state: CLRegionState,
    for region: CLRegion)
  {
    switch state {
    case .inside:
      locationManager.startRangingBeacons(in: beaconRegion)
    case .outside, .unknown:
      locationManager.stopRangingBeacons(in: beaconRegion)
    }
  }
  
  public func locationManager(
    _ manager: CLLocationManager,
    didEnterRegion region: CLRegion)
  {
    locationManager.startRangingBeacons(in: beaconRegion)
  }
  
  public func locationManager(
    _ manager: CLLocationManager,
    didExitRegion region: CLRegion)
  {
    locationManager.stopRangingBeacons(in: beaconRegion)
  }
  
  public func locationManager(
    _ manager: CLLocationManager,
    didRangeBeacons beacons: [CLBeacon],
    in region: CLBeaconRegion)
  {
    guard let beacon = beacons.first else { return }
    onProximityChange?(self, beacon.proximity)
  }
  
  public func locationManager(
    _ manager: CLLocationManager,
    monitoringDidFailFor region: CLRegion?,
    withError error: Error)
  {
    onError?(error)
  }
  
  public func locationManager(
    _ manager: CLLocationManager,
    rangingBeaconsDidFailFor region: CLBeaconRegion,
    withError error: Error)
  {
    onError?(error)
  }
  
  public func locationManager(
    _ manager: CLLocationManager,
    didFailWithError error: Error)
  {
    onError?(error)
  }
}

enum BeaconRangerError: Error {
  case locationDenied
  case locationRestricted
  case backgroundRefreshDenied
  case backgroundRefreshRestricted
}
