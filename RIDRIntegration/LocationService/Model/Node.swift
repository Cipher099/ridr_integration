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
//        let containsKey = dictionary.contains { (key: String, value: AnyObject) -> Bool in
//            return key == "features"
//        }
//        if !containsKey { return nil }
        guard let features = dictionary["features"] as? [AnyObject] else { return nil }
        guard let geometries = features.first!["geometry"] as? [String:AnyObject] else { return nil }
        guard let coords = geometries["coordinates"] as? [[Double]] else { return nil }
        let nodeArray = coords.map({ (item) -> Node in
            let node = Node(item[0], Lng: item[1])
            node.legDistance = 5.0 // Default leg distance to 5 for now
            return node
        })
        return nodeArray
    }
}
