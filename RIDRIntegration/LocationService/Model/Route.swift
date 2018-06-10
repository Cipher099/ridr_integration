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


class Route: NSObject {
    
    let LOCATION_FUZZY_EQUAL_THRESHOLD_DEGREES: Double = 0.00001
    let CLOCKWISE_DEGREES: Double = 90.0
    let COUNTERCLOCKWISE_DEGREES: Double = -90.0
    let CORRECTION_THRESHOLD_METERS: Double = 1000
    let REVERSE_DEGREES: Double = 180
    let LOST_THRESHOLD_METERS: Double = 50
    let CLOSE_TO_DESTINATION_THRESHOLD_METERS: Double = 20
    let CLOSE_TO_NEXT_LEG_THRESHOLD_METERS: Double = 5
    
    /// The start location of the route
    fileprivate var startLocation: CLLocation
    
    /// The end location of the route
    fileprivate var endLocation: CLLocation
    
    /// the last acquired location of the route
    fileprivate var lastLocation: CLLocation?
    
    /// The stored data, which is required from instantiation
    fileprivate var routeData: Array<Node>?
    
    /// A flag for if a user has gone off route and to notify observing instances
    public fileprivate(set) var isRouting: Bool = false {
        didSet {
            let notification = Notification(name: Notification.Name(rawValue: "isRouting"),
                        object: nil, userInfo: ["status": self.isRouting])
            NotificationCenter.default.post(notification)
        }
    }
    private var lost = false
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
        return false
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
        return route
    }
    
    /**
     Makes a copy of the incoming multiline string object for use with
     the routing object
     - parameter route: The line segment which the route will follow
     */
    public static func createRoute (_ multiLineString: MultiLineString<LineString>) -> Route {
        let route = Route()
//        route.routeData = multiLineString
//        if let startCoords = multiLineString.geometries.first(where: { (item) -> Bool in return true }) {
//            route.startLocation = CLLocation(latitude: startCoords.middlePoint().coordinate.x,
//                                                         longitude: startCoords.middlePoint().coordinate.y)
//        }
//        
//        if let endCoords = multiLineString.geometries.reversed().first(where: { (item) -> Bool in return true }) {
//            route.endLocation = CLLocation(latitude: endCoords.middlePoint().coordinate.x,
//                                                       longitude: endCoords.middlePoint().coordinate.y)
//        }
        
        return route
    }
    public static func createRoute (_ nodes: Array<Node>) -> Route {
        let route = Route()
        return route
    }
    /**
     From the data provided in the enter region request, determine if the location can
     be sent to the server
     - parameter locations: Array of the latest location
     - returns: true if the user can be beacon, false otherwise
     */
    func determineBeacon (Locations locations: [CLLocation]) -> Bool {
        return lost
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
        let sizeOfPoly = self.routeData?.count
        
        // we are lost
        if pastEndOfRoute {
            lost = true
            return nil
        }
        
        // snap to destination location
        if (closeToDestination(location: currentLocation)) {
            let destination = routeData![sizeOfPoly! - 1]
//            updateDistanceTravelled(destination)
            return currentLocation // destination.locations
        }
        
        // snap currentNode's location to a location along the route, if we are close
        // to the next leg, go to next leg and then retry snapping
        let currentNode = routeData![currentLeg]
        lastLocation = snapTo(currentNode, location: currentLocation.coordinate, degreeOffset: 1)
        if (lastLocation == nil) {
            lastLocation = currentLocation // currentNode.location
        } else {
            let current = CLLocation(latitude: currentNode.lat, longitude: currentNode.lng)
            if (closeToNextLeg(location: current, legDistance: currentNode.legDistance)) {
                currentLeg += 1
//                updateCurrentInstructionIndex()
                return snapToRoute(currentLocation)
            }
        }
        
        if (beginningRouteLostThresholdMeters == nil) {
            var distanceToFirstLoc = currentLocation.distance(from: (routeData!.first?.location)!)
            beginningRouteLostThresholdMeters = distanceToFirstLoc + LOST_THRESHOLD_METERS
        }
        
        // if we are close to the route, return snapped location on route, if we havent started
        // route and we arent close to another part of the route, dont consider user lost.
        // otherwise user is in middle of route but far from fixed location along route and
        // is therefore lost
        let distanceToRoute = currentLocation.distance(from: lastLocation!)
        if distanceToRoute < LOST_THRESHOLD_METERS {
//            updateDistanceTravelled(currentNode)
            return lastLocation
        } else if /*totalDistanceTravelled == 0.0 &&*/ currentLeg == 0
            && distanceToRoute < beginningRouteLostThresholdMeters! {
            return currentLocation
        } else {
            lost = true
            return nil
        }
        return currentLocation
    }
    
    /**
     Returns the closes location along the current route segment that the location should  snap to
     
     - parameter node:
     - parameter location:
     - returns: location along route to snap to
     */
    private func snapTo (_ node: Node, Location location: CLLocation) -> CLLocation {
        // if lat/lng of node and location are same, just update location's bearing to node
        // and snap to it
        if (fuzzyEqual(l1: node.location, l2: location)) {
//            updateDistanceTravelled(node)
//            location.bearing = node.bearing.toFloat()
            return CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
        
        var correctedLocation = snapTo(node, location: location.coordinate, degreeOffset: CLOCKWISE_DEGREES)
        if (correctedLocation == nil) {
            correctedLocation = snapTo(node, location: location.coordinate, degreeOffset: COUNTERCLOCKWISE_DEGREES)
        }
        
        if correctedLocation != nil {
            let temp = CLLocation(latitude: (correctedLocation?.coordinate.latitude)!, longitude: (correctedLocation?.coordinate.longitude)!)
            let locationLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
            let distance = temp.distance(from: locationLocation) //correctedLocation.distanceTo(location).toDouble()
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
        
//        var bearingDelta = node.bearing - node.location.bearingTo(correctedLocation).toDouble()
//        if (abs(bearingDelta) > 10 && abs(bearingDelta) < 350) {
//            correctedLocation = node.location
//        }
        
//        correctedLocation?.bearing = node.location.bearing
        
        return correctedLocation!
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
        
//        var loc = CLLocation()
//        loc.latitude = lat3.radiansToDegrees // toDegrees(lat3)
//        loc.longitude = lon3.radiansToDegrees // toDegrees(lon3)
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
        return location.distance(from: lastLocation!) > legDistance - CLOSE_TO_NEXT_LEG_THRESHOLD_METERS
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
