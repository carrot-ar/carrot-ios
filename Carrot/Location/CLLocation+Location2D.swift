//
//  CLLocationExtensions.swift
//  Carrot
//
//  Created by Gonzalo Nunez on 10/23/17.
//  Copyright © 2017 carrot. All rights reserved.
//

import CoreLocation
import Foundation

extension CLLocation {
  public convenience init(location2D: Location2D) {
    self.init(
      coordinate: CLLocationCoordinate2D(
        latitude: location2D.latitude.converted(to: .degrees).value,
        longitude: location2D.longitude.converted(to: .degrees).value),
      altitude: location2D.altitude.converted(to: .meters).value,
      horizontalAccuracy: kCLLocationAccuracyBest,
      verticalAccuracy: kCLLocationAccuracyBest,
      timestamp: Date())
  }
}
