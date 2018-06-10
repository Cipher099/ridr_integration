//
//  Integration.swift
//  RIDRIntegration
//
//  Created by Burton Wevers on 2018/06/06.
//  Copyright © 2018 ZATools. All rights reserved.
//

import Foundation
import CoreLocation

public let R = RIDR.instance

open class RIDR: NSObject {
    
    static let instance = RIDR()
    
    private override init() { }
    
    /**
     Register device on the network in order for it to be notified and made
     aware of issues. Also for the purpose of verifying the device on the network
     - parameter deviceIdentifier: the deviceIdentifier to be identified on the network
     */
    func postRegistration (deviceIdentifier: String) {}
    
    /**
     Post the application registration to the server in order to ask for ad hoc
     location information
     
     - note: this is not for all applications
     */
    func postDeviceTokenToServer (deviceToken: String) {}
    
    /**
     If the user allows send the location information to the server in order to
     assist other user's of a transport mode's location
     @note: Will be shutdown down once the user leaves a station
     */
    func sendLocation (location: CLLocation, heading: CLHeading?) {}
    
    /**
     If the user allows send the location information to the server in order to
     assist other user's of a transport mode's location
     @note: Will be shutdown down once the user leaves a station
     - parameter location: The current location of a user when event is triggered
     - parameter isEntering: true if the region is being entered, false otherwise
     */
    func sendLocation (location: CLLocation, isEntering: Bool) {}
    
    /**
     Determined by the server if a user can be a beacon for the system, flag returns
     parameters to indicate the user can be a beacon or not
     */
//    func canBeBeacon (longitude: Double, Latitude: Double, heading: CLHeading?, flag: (Bool) -> ()) {
//        flag(true)
//    }
    
    /**
     Query the server for the route the next 3 vehicles will be taking from the station
     to supply the server with better data to supply other users.
     - parameter stationIdentifier: the system designated identifier of a station
     - parameter data: the dictionary with the geojson data for helping with tracking
     - note: Need to convert the dictionary to an object
     */
    func acquireRoute(stationIdentifier: String, data: ((_ data: [String:AnyObject]) -> ())? = nil) {}
    
    /**
     Primarily for the Geofencing points, this method could also be used for
     querying the closest stations for visual purposes.
     
     - parameter location: the location of the region the client entered
     - parameter stations: the returned data to the method for consumption
     - note: Need to make this dictionary an object?
     */
    func getClosestStations (location: CLLocationCoordinate2D, stations: (_ data: [String:AnyObject]) -> ()) {}
    
    /**
     With the identifier from the device, sync the data to the server to acquire better
     data and geofencing capability
     - parameter newData: The new data for the sync from server
     */
    func syncServerData (newData: (_ data: [String:AnyObject]) -> (Bool)) {}
}
