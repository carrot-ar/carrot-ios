//
//  PeripheralAdvertiser.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/30/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import Foundation
import CoreBluetooth
import CoreLocation

public final class BeaconAdvertiser: NSObject {
  
  // MARK: Lifecycle
  
  public init(uuid: UUID) {
    //FIXME: What should we use for major and/or minor if we are the primary device?
    beaconRegion = CLBeaconRegion(
      proximityUUID: uuid,
      major: 100,
      minor: 100,
      identifier: "com.carrot.PrimaryDeviceBeaconRegion")
    super.init()
  }
  
  deinit {
    stopAdvertising()
  }
  
  // MARK: Public
  
  public var isAdvertising: Bool {
    return peripheral.isAdvertising
  }
  
  public func startAdvertising(onStateChange: @escaping (BeaconAdvertiser, BeaconAdvertisingState) -> Void) {
    stateHandler = onStateChange
    updateAdvertisingState()
  }
  
  public func stopAdvertising() {
    peripheral.stopAdvertising()
    advertisingState = .idle
  }
  
  // MARK: Private
  
  private var stateHandler: ((BeaconAdvertiser, BeaconAdvertisingState) -> Void)!
  private var advertisingState: BeaconAdvertisingState = .idle {
    didSet { stateHandler(self, advertisingState) }
  }
  
  private let beaconRegion: CLBeaconRegion
  private lazy var peripheral: CBPeripheralManager = {
    return CBPeripheralManager(delegate: self, queue: nil)
  }()
  
  private func updateAdvertisingState() {
    if peripheral.isAdvertising {
      return
    }
    let peripheralState = peripheral.state
    switch peripheralState {
    case .poweredOn:
      let data = beaconRegion.peripheralData(withMeasuredPower: nil) as! [String: Any]
      peripheral.startAdvertising(data)
    case .poweredOff:
      advertisingState = .queued
    case .unsupported:
      advertisingState = .error(BeaconAdvertiserError.unsupported)
    case .unauthorized:
      advertisingState = .error(BeaconAdvertiserError.unauthorized)
    case .unknown, .resetting:
      advertisingState = .queued
    }
  }
}

extension BeaconAdvertiser: CBPeripheralManagerDelegate {
  public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    updateAdvertisingState()
  }
  
  public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
    if let error = error {
      advertisingState = .error(error)
    } else {
      advertisingState = .advertising
    }
  }
}

public enum BeaconAdvertisingState {
  /// Waiting for the call to startAdvertising(_:_:)
  case idle
  /// Waiting for the `CBManagerState` to change from .poweredOff, .unknown, or .resetting
  case queued
  /// The CBPeripheralManager is currently advertising `beaconRegion`
  case advertising
  /// An error occured
  case error(Error)
}

public enum BeaconAdvertiserError: Error {
  case unsupported
  case unauthorized
}
