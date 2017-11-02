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
  
  init(uuid: UUID) {
    //FIXME: What should we use for major and/or minor?
    beaconRegion = CLBeaconRegion(
      proximityUUID: uuid,
      major: 100,
      minor: 100,
      identifier: "com.carrot.PrimaryDeviceBeaconRegion")
    super.init()
  }
  
  deinit {
    peripheral.stopAdvertising()
  }
  
  // MARK: Internal
  
  func startAdvertising(
    onStateChange: @escaping (BeaconAdvertisingState) -> Void,
    onImmediatePing: @escaping () -> Void)
  {
    stateHandler = onStateChange
    didSendImmediatePing = onImmediatePing
    updateAdvertisingState()
  }
  
 func stopAdvertising() {
    peripheral.stopAdvertising()
    advertisingState = .idle
  }
  
  // MARK: Private
  
  private var didSendImmediatePing: (() -> Void)!
  private var stateHandler: ((BeaconAdvertisingState) -> Void)!
  private var advertisingState: BeaconAdvertisingState = .off {
    didSet { stateHandler(advertisingState) }
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
      advertisingState = .off
    case .unsupported, .unauthorized:
      advertisingState = .error(BeaconAdvertiserError.badState(peripheralState))
    case .unknown, .resetting:
      advertisingState = .queued
    }
    print("Peripheral state: \(peripheral.state)")
    print("Advertising state: \(advertisingState)")
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

enum BeaconAdvertisingState {
  case off
  case idle
  case queued
  case advertising
  case error(Error)
}

enum BeaconAdvertiserError: Error {
  case badState(CBManagerState)
}
