//
//  Route.swift
//  RIDRIntegration
//
//  Created by Burton Wevers on 2018/06/09.
//  Copyright © 2018 ZATools. All rights reserved.
//

import Foundation
import CoreLocation
import GEOSwift

/**
 Route class adapted from the on the road project
 https://github.com/Cipher099/on-the-road_android/blob/master/library/src/main/java/com/mapzen/valhalla/Route.kt
 */
class Route: NSObject {
    
    private let LOCATION_FUZZY_EQUAL_THRESHOLD_DEGREES: Double = 0.00001
    private let CLOCKWISE_DEGREES: Double = 90.0
    private let COUNTERCLOCKWISE_DEGREES: Double = -90.0
    private let CORRECTION_THRESHOLD_METERS: Double = 1000
    private let REVERSE_DEGREES: Double = 180
    private let LOST_THRESHOLD_METERS: Double = 50
    private let CLOSE_TO_DESTINATION_THRESHOLD_METERS: Double = 20
    private let CLOSE_TO_NEXT_LEG_THRESHOLD_METERS: Double = 5
    private let MINIMUM_ROUTE_DATA_THRESHOLD: Int = 2
    
    /// The start location of the route
    fileprivate var startLocation: CLLocation
    
    /// The end location of the route
    fileprivate var endLocation: CLLocation
    
    /// the last acquired location of the route
    fileprivate var lastLocation: CLLocation?
    
    /// The stored data, which is required from instantiation
    fileprivate var routeData: Array<Node>?
    
    /// Flag for if the route object is valid
    public var isValid: Bool {
        guard let routedata = self.routeData else {
            return false
        }
        return routedata.count > MINIMUM_ROUTE_DATA_THRESHOLD
    }
    
    /// A flag for if a user has gone off route and to notify observing instances
    public fileprivate(set) var isRouting: Bool = false {
        didSet {
            let notification = Notification(name: Notification.Name(rawValue: "isRouting"),
                        object: nil, userInfo: ["status": self.isRouting])
            NotificationCenter.default.post(notification)
        }
    }
    
    /// Flag variable to indicate if the user is lost
    private var lost = false
    
    /// The index of the route currently being taken
    private var currentLeg: Int = 0
    private var beginningRouteLostThresholdMeters: Double?
    
    /// Notify the router that the current route has almost reached the destination
    public fileprivate(set) var closeToDest: Bool = false {
        didSet {
            let notification = Notification(name: Notification.Name(rawValue: "closeToDestination"),
                                                object: nil, userInfo: ["status": self.closeToDestination])
            NotificationCenter.default.post(notification)
        }
    }
    
    /// Flag for if route has been passed
    private var pastEndOfRoute: Bool {
        guard let routedata = self.routeData else { return true }
        return currentLeg > routedata.count
    }
    
    private override init() {
        self.startLocation = CLLocation(latitude: 0, longitude: 0)
        self.endLocation = CLLocation(latitude: 0, longitude: 0)
    }

    /**
     Parses the incoming dictionary and creates a multiline string
     to be consumed by the route object
     */
    public static func createRoute (_ data: [String:AnyObject] ) -> Route {
        let route = Route()
        route.routeData = Node.createNodeArrayFrom(data)
        return route
    }
    
    /**
     Makes a copy of the incoming multiline string object for use with
     the routing object
     - parameter route: The line segment which the route will follow
     - returns: The Route object to be used for keeping track of a client
     */
    
    public static func createRoute (_ nodes: Array<Node>) -> Route {
        let route = Route()
        route.routeData = nodes
        return route
    }
    /**
     From the data provided in the enter region request, determine if the location can
     be sent to the server
     - parameter locations: Array of the latest location
     - returns: true if the user can be beacon, false otherwise
     */
    func determineBeacon (Locations locations: [CLLocation]) -> Bool {
        return !self.lost
    }
    
    /**
     Takes current location and tries to snap it to a location along the route. If we are past
     the end of the poly line, consider user lost and don't return location to snap to. If we are
     close to destination, snap to the destination location. If we are close to the next leg of
     route, increment current leg and rerun this function otherwise get fixed location along
     route which is closest to user's current location. If user's location is within certain
     distance to route, snap to that location along path, otherwise consider user lost, dont
     snap to anything
     
     - parameter currentLocation: the curent location of the client
     - returns: the next location to be snapped to
     */
    public func snapToRoute(_ currentLocation: CLLocation) -> CLLocation? {
        self.lastLocation = currentLocation
        guard let routedata = self.routeData else { return nil }
        let sizeOfPoly = routedata.count
        
        // we are lost
        if pastEndOfRoute {
            lost = true
            return nil
        }
        
        // snap to destination location
        if (closeToDestination(location: currentLocation)) {
            let destination = routedata[sizeOfPoly - 1]
            return destination.location
        }
        
        // snap currentNode's location to a location along the route, if we are close
        // to the next leg, go to next leg and then retry snapping
        let currentNode = routedata[currentLeg]
        lastLocation = snapTo(currentNode, Location: currentLocation)
        if (lastLocation == nil) {
            lastLocation = currentLocation
            // If the route supplied is too much, look for the closest leg
            currentLeg = findClosestLeg(currentLocation)
            if currentLeg == -1 || pastEndOfRoute {
                lost = true
                return nil
            }
        } else {
            let current = currentNode.location
            if (closeToNextLeg(location: current, legDistance: currentNode.legDistance)) {
                currentLeg += 1
                return snapToRoute(currentLocation)
            }
        }
        
        // What does this actually do?
        if (beginningRouteLostThresholdMeters == nil) {
            let distanceToFirstLoc = currentLocation.distance(from: (routeData!.first?.location)!)
            beginningRouteLostThresholdMeters = distanceToFirstLoc + LOST_THRESHOLD_METERS
        }
        
        // if we are close to the route, return snapped location on route, if we havent started
        // route and we arent close to another part of the route, dont consider user lost.
        // otherwise user is in middle of route but far from fixed location along route and
        // is therefore lost
        let distanceToRoute = currentLocation.distance(from: lastLocation!)
        if distanceToRoute < LOST_THRESHOLD_METERS {
            return lastLocation
        } else if currentLeg == 0 && distanceToRoute < beginningRouteLostThresholdMeters! {
            return currentLocation
        } else {
            lost = true
            return nil
        }
    }
    
    /**
     Returns the closes location along the current route segment that the location should  snap to
     
     - parameter node: the node the user can be snapped to
     - parameter location: The location the user is currently at
     - returns: location along route to snap to
     */
    private func snapTo (_ node: Node, Location location: CLLocation) -> CLLocation? {
        // if lat/lng of node and location are same, just update location's bearing to node
        // and snap to it
        if (fuzzyEqual(l1: node.location, l2: location)) {
            return CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
        
        var correctedLocation = snapTo(node, location: location.coordinate, degreeOffset: CLOCKWISE_DEGREES)
        if (correctedLocation == nil) {
            correctedLocation = snapTo(node, location: location.coordinate, degreeOffset: COUNTERCLOCKWISE_DEGREES)
        }
        
        if correctedLocation != nil {
            let temp = CLLocation(latitude: (correctedLocation?.coordinate.latitude)!, longitude: (correctedLocation?.coordinate.longitude)!)
            let locationLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
            let distance = temp.distance(from: locationLocation)
            // check if results are on the otherside of the globe
            if (round(distance) > CORRECTION_THRESHOLD_METERS) {
                let tmpNode = Node(node.lat, Lng: node.lng)
                tmpNode.bearing = node.bearing - REVERSE_DEGREES
                correctedLocation = snapTo(tmpNode, location: location.coordinate, degreeOffset: CLOCKWISE_DEGREES)
                if (correctedLocation == nil) {
                    correctedLocation = snapTo(tmpNode, location: location.coordinate, degreeOffset: COUNTERCLOCKWISE_DEGREES)
                }
            }
        }
        
//        if let snappedLocation = correctedLocation {
//            let bearingDelta = node.bearing - node.location.bearingToLocationDegrees(destinationLocation: snappedLocation)
//            if (abs(bearingDelta) > 10 && abs(bearingDelta) < 350) {
//                correctedLocation = node.location
//            }
//            correctedLocation?.bearing = node.location.bearing
//        }
        return correctedLocation
    }
    
    /**
     * Uses haversine formula (http://www.movable-type.co.uk/scripts/latlong.html) to calculate
     * closest location along current route segment
     *
     * @param node Current node
     * @param location User's current location
     * @param degreeOffset Degrees to offset node bearing
     */
    private func snapTo(_ node: Node, location: CLLocationCoordinate2D, degreeOffset: Double) -> CLLocation? {
        let lat1 = node.lat.degreesToRadians// toRadians(node.lat)
        let lon1 = node.lng.degreesToRadians
        let lat2 = location.latitude.degreesToRadians
        let lon2 = location.longitude.degreesToRadians
        
        let brng13 = node.bearing.degreesToRadians // toRadians(node.bearing)
        let brng23 = (node.bearing + degreeOffset).degreesToRadians // toRadians(node.bearing + degreeOffset)
        
        let dLat = lat2 - lat1
        var dLon = lon2 - lon1
        if (dLon == 0.0) {
            dLon = 0.001
        }
        
        let dist12 = 2 *  asin(sqrt( sin(dLat / 2) *  sin(dLat / 2) + cos(lat1) *  cos(lat2) *  sin(dLon / 2) *  sin(dLon / 2)))
        if (dist12 == 0.0) { return nil }
        
        // initial/final bearings between points
        let brngA =  acos(( sin(lat2) -  sin(lat1) *  cos(dist12)) / ( sin(dist12) *  cos(lat1)))
        
        let brngB =  acos(( sin(lat1) -  sin(lat2) *  cos(dist12)) / ( sin(dist12) *  cos(lat2)))
        
        var brng12: Double
        var brng21: Double
        if ( sin(lon2 - lon1) > 0) {
            brng12 = brngA
            brng21 = 2 *  .pi - brngB
        } else {
            brng12 = 2 *  .pi - brngA
            brng21 = brngB
        }
        
        let alpha1 = (brng13 - brng12 + .pi).truncatingRemainder(dividingBy:  (2 * .pi) - .pi)  // angle 2-1-3
        let alpha2 = (brng21 - brng23 + .pi).truncatingRemainder(dividingBy:  (2 * .pi) - .pi)  // angle 1-2-3
        
        if ( sin(alpha1) == 0.0 &&  sin(alpha2) == 0.0) {
            return nil  // infinite intersections
        }
        if ( sin(alpha1) *  sin(alpha2) < 0) {
            return nil       // ambiguous intersection
        }
        
        let alpha3 =  acos(-cos(alpha1) *  cos(alpha2) +  sin(alpha1) *  sin(alpha2) *  cos(dist12))
        let dist13 =  atan2( sin(dist12) *  sin(alpha1) *  sin(alpha2), cos(alpha2) +  cos(alpha1) *  cos(alpha3))
        let lat3 =  asin( sin(lat1) *  cos(dist13) +  cos(lat1) *  sin(dist13) *  cos(brng13))
        let dLon13 =  atan2( sin(brng13) *  sin(dist13) *  cos(lat1), cos(dist13) -  sin(lat1) *  sin(lat3))
        // normalise to -180..+180º
        let lon3 = ((lon1 + dLon13) + 3 * .pi).truncatingRemainder(dividingBy: (2 *  .pi) -  .pi)
        
        return CLLocation(latitude: lat3.radiansToDegrees, longitude: lon3.radiansToDegrees)
    }
    
    /**
     * Determine if these two locations are more or less the same to avoid doing extra calculations
     */
    private func fuzzyEqual(l1: CLLocation, l2: CLLocation) -> Bool {
        let deltaLat =  abs(l1.coordinate.latitude - l2.coordinate.latitude)
        let deltaLng =  abs(l1.coordinate.longitude - l2.coordinate.longitude)
        return (deltaLat <= LOCATION_FUZZY_EQUAL_THRESHOLD_DEGREES)
            && (deltaLng <= LOCATION_FUZZY_EQUAL_THRESHOLD_DEGREES)
    }
    
    /**
     * If the distance from this location to the last fixed location is almost the length of the
     * leg, then we are close to the next leg
     */
    private func closeToNextLeg(location: CLLocation, legDistance: Double) -> Bool {
        return location.distance(from: lastLocation!) > (legDistance - CLOSE_TO_NEXT_LEG_THRESHOLD_METERS)
    }
    
    /**
     If the routedata was acquired and the route which is supposed to be snapped is not correct,
     try and find the closest point within the threshold to link to in order to continue the
     data stream
     
     - parameters location - the current location of a user
     - returns: the legs in the routedata which is usable to route
     */
    private func findClosestLeg (_ location: CLLocation) -> Int {
        guard let routedata = self.routeData else { return -1 }
        guard let index = routedata.index(where: { (node) -> Bool in
            return node.location.distance(from: location) < CLOSE_TO_NEXT_LEG_THRESHOLD_METERS
        }) else { return -1 }
        return index
    }
    
    /**
     * If the distance from {@param location} to last node in poly is less than
     * {@link CLOSE_TO_DESTINATION_THRESHOLD} user is close to destination
     */
    private func closeToDestination(location: CLLocation) -> Bool {
        let destination = routeData?.last
        let distanceToDestination = destination?.location.distance(from: location)
        return floor(distanceToDestination!) < CLOSE_TO_DESTINATION_THRESHOLD_METERS
    }
}
