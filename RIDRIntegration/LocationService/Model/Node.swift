//
//  Node.swift
//  RIDRIntegration
//
//  Created by Burton Wevers on 2018/06/09.
//  Copyright © 2018 ZATools. All rights reserved.
//

import Foundation
import CoreLocation

open class Node: NSObject {
    
    var totalDistance: Double = 0.0
    var bearing: Double = 0.0
    var legDistance: Double = 0.0
    var location: CLLocation
    var loc: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.location.coordinate.latitude,
                                      
                                      longitude: self.location.coordinate.longitude)
    }
    
    var lat: Double {
        return location.coordinate.latitude
    }
    
    var lng: Double {
        return location.coordinate.longitude
    }
    
    open override var description: String {
        return "[LAT: \(location.coordinate.latitude), LNG: \(location.coordinate.longitude) LEGDIST: \(legDistance)"
    }
    
    init(_ lat: Double, Lng lng: Double) {
        self.location = CLLocation(latitude: lat, longitude: lng)
    }
    
    init(_ location: CLLocationCoordinate2D) {
//        self.loc = location
        self.location = CLLocation(latitude: location.latitude, longitude: location.longitude)
    }
}
