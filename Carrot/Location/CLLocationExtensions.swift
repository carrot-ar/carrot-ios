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
  convenience init(location2D: Location2D) {
    self.init(
      latitude: location2D.latitude.converted(to: .degrees).value,
      longitude: location2D.longitude.converted(to: .degrees).value)
  }
}
