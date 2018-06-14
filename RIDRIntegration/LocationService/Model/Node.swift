//
//  Node.swift
//  RIDRIntegration
//
//  Created by Burton Wevers on 2018/06/09.
//  Copyright © 2018 ZATools. All rights reserved.
//

import Foundation
import CoreLocation
import GEOSwift

open class Node: NSObject {
    
    var totalDistance: Double = 0.0
    
    // The heading direction of the device
    var bearing: Double = 0.0
    
    /// The distance from this leg to the next
    var legDistance: Double = 0.0
    var location: CLLocation
    var loc: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.location.coordinate.latitude, longitude: self.location.coordinate.longitude)
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
        self.location = CLLocation(latitude: location.latitude, longitude: location.longitude)
    }
    
    /**
     Validates and creates an array of nodes to be consumed by the route class
     - parameter dictionary: The data to be validate and parsed for the route
     - returns: An array representation of the route
     */
    static func createNodeArrayFrom(_ dictionary: [String:AnyObject]) -> Array<Node>? {
        guard let feature = Features.fromGeoJSONDictionary(dictionary) else {
            return nil
        }
        guard let firstFeature = feature.first,
            let geometries = firstFeature.geometries else {
                return nil
        }
        guard let lineString = geometries.first as? LineString else {
            return nil
        }
        let nodeArray = lineString.points.map { (coords) -> Node in
            return Node(coords.x, Lng: coords.y)
        }
        return nodeArray
    }
}
