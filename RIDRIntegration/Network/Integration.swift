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
     Query the server for the route the next 3 vehicles will be taking from the station
     to supply the server with better data to supply other users.
     - parameter stationIdentifier: the system designated identifier of a station
     - parameter data: the dictionary with the geojson data for helping with tracking
     - note: Need to convert the dictionary to an object
     */
    func acquireRoute(stationIdentifier: String, route: @escaping ((_ data: [String:AnyObject]) -> ())) {
        let jsonData: [String : Any] = [
            "station": stationIdentifier
        ]
        guard let url = URL(string: "http://localhost:3000/data/route") else {
            route([:])
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("29b98166-da89-4438-93b1-a8a0d9377b12", forHTTPHeaderField: "x-api-key")
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: jsonData)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print(error!)
                route([:])
                return
            }
            guard let data = data else {
                print("Data is empty")
                route([:])
                return
            }
            do {
                guard let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {
                    route([:])
                    return
                }
                route(jsonDictionary)
            } catch {
                // Handle error
                print(error)
                route([:])
            }
        }
        task.resume()
    }
    
    /**
     Primarily for the Geofencing points, this method could also be used for
     querying the closest stations for visual purposes.
     
     - parameter location: the location of the region the client entered
     - parameter resultCount: the amount the client wants the server to return
     - parameter stations: the returned data to the method for consumption
     - note: Need to make this dictionary an object?
     */
    func getClosestStations (location: CLLocationCoordinate2D, ResultCount resultCount: Int, TransportType type: String? = nil, stations: @escaping (_ data: [AnyObject]) -> ()) {
        // To be used to only retreive certain transport type
        var stationType = "brt_station"
        if type != nil { stationType = type! }
        guard let url = URL(string: "http://localhost:3000/data/closest?resultCount=10") else {
            stations([])
            return
        }
        let jsonData: [String : Any] = [
            "lat": location.latitude,
            "lon": location.longitude,
            "type": stationType
        ]
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("29b98166-da89-4438-93b1-a8a0d9377b12", forHTTPHeaderField: "x-api-key")
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: jsonData)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print(error!)
                stations([])
                return
            }
            guard let data = data else {
                print("Data is empty")
                stations([])
                return
            }
            do {
                guard let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [AnyObject] else {
                    stations([])
                    return
                }
                stations(jsonDictionary)
            } catch {
                // Handle error
                print(error)
                stations([])
            }
        }
        task.resume()
    }
    
    /**
     With the identifier from the device, sync the data to the server to acquire better
     data and geofencing capability
     - parameter newData: The new data for the sync from server
     */
    func syncServerData (newData: (_ data: [String:AnyObject]) -> (Bool)) {}
}
