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
    private static var BASE_URL: String {
        return "http://localhost:3000"
    }
    
    static let instance = RIDR()
    
    private override init() { }
    
    /**
     Register device on the network in order for it to be notified and made
     aware of issues. Also for the purpose of verifying the device on the network
     - parameter deviceIdentifier: the deviceIdentifier to be identified on the network
     */
    func postRegistration (deviceIdentifier: String) {
        let jsonData: [String : Any] = [
            "station": deviceIdentifier
        ]
        let completeBlock: ((String?, Error?) ->()) = { (info, error) in
            
        }
        createRequest("/data/route", Method: "POST", Data: jsonData, completion: completeBlock)
    }
    
    /**
     Post the application registration to the server in order to ask for ad hoc
     location information
     
     - note: this is not for all applications
     */
    func postDeviceTokenToServer (deviceToken: String) {
        let jsonData: [String : Any] = [
            "station": deviceToken
        ]
        let completeBlock: ((String?, Error?) ->()) = { (info, error) in
            
        }
        createRequest("/data/route", Method: "POST", Data: jsonData, completion: completeBlock)
    }
    
    /**
     If the user allows send the location information to the server in order to
     assist other user's of a transport mode's location
     @note: Will be shutdown down once the user leaves a station
     */
    func sendLocation (location: CLLocation, heading: CLHeading?) {
        let jsonData: [String : Any] = [
            "station": location
        ]
        let completeBlock: ((String?, Error?) ->()) = { (info, error) in
            
        }
        createRequest("/data/route", Method: "POST", Data: jsonData, completion: completeBlock)
    }
    
    /**
     If the user allows send the location information to the server in order to
     assist other user's of a transport mode's location
     @note: Will be shutdown down once the user leaves a station
     - parameter location: The current location of a user when event is triggered
     - parameter isEntering: true if the region is being entered, false otherwise
     */
    func sendLocation (location: CLLocation, isEntering: Bool) {
        let jsonData: [String : Any] = [
            "station": location
        ]
        let completeBlock: ((String?, Error?) ->()) = { (info, error) in
            
        }
        createRequest("/data/route", Method: "POST", Data: jsonData, completion: completeBlock)
    }
    
    /**
     Query the server for the route the next 3 vehicles will be taking from the station
     to supply the server with better data to supply other users.
     - parameter stationIdentifier: the system designated identifier of a station
     - parameter data: the dictionary with the geojson data for helping with tracking
     - note: Need to convert the dictionary to an object
     */
    func acquireRoute(stationIdentifier: String, route: @escaping ((_ data: [String:AnyObject]) -> ())) {
        let jsonData: [String : Any] = [
            "identifier": stationIdentifier // The system-designated identifier
        ]
        let completeBlock: ((RouteData?, Error?) ->()) = { (info, error) in
            
        }
        createRequest("/data/route", Method: "POST", Data: jsonData, completion: completeBlock)
    }
    
    /**
     Primarily for the Geofencing points, this method could also be used for
     querying the closest stations for visual purposes.
     
     - parameter location: the location of the region the client entered
     - parameter resultCount: the amount the client wants the server to return
     - parameter stations: the returned data to the method for consumption
     - note: Need to make this dictionary an object?
     */
    func getClosestStations (location: CLLocationCoordinate2D, ResultCount resultCount: Int? = 10, TransportType type: String? = nil, stations: @escaping (_ data: [AnyObject]) -> ()) {
        // Construct the URL
        var stationType = "brt_station"
        if type != nil { stationType = type! }
        let jsonData: [String : Any] = [
            "lat": location.latitude,
            "lon": location.longitude,
            "type": stationType
        ]
        let completeBlock: ((Stations?, Error?) ->()) = { (info, error) in
            
        }
        createRequest("/data/closest?resultCount=\(resultCount!)", Method: "POST", Data: jsonData, completion: completeBlock)
    }
    
    /**
     With the identifier from the device, sync the data to the server to acquire better
     data and geofencing capability
     - parameter newData: The new data for the sync from server
     */
    func syncServerData (newData: (_ data: [String:AnyObject]) -> (Bool)) {
        let URL = ""
        let Data: [String:Any] = [:]
        let completeBlock: ((String?, Error?) ->()) = { (info, error) in
            
        }
        createRequest(URL, Method: "POST", Data: Data, completion: completeBlock)
    }
    
    /**
     Creates a request for the provided URL with the method specified and the data to
     fulfil the request
     
     - parameter url: The URL of the request (must include the prefixed /)
     - parameter method: The request method (optional, defaults to GET)
     - parameter jsonData: The json data to complete the request
     - parameter completion: The completion handler for the received data from server
     */
    private func createRequest<T:Codable>(_ url: String, Method method: String? = "GET", Data jsonData: [String:Any]?, completion: @escaping ((T?, Error?) ->())) -> Void {
        guard let url = URL(string: "\(RIDR.BASE_URL)\(url)") else {
            completion(nil, CustomError.InvalidURL)
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("29b98166-da89-4438-93b1-a8a0d9377b12", forHTTPHeaderField: "x-api-key")
        request.httpMethod = method
        if let unwrappedJsonData = jsonData {
            request.httpBody = try? JSONSerialization.data(withJSONObject: unwrappedJsonData)
        }
        
        let task = URLSession.shared.dataTask(with: request) { (data, urlResponse, error) in
            if error != nil {
                completion(nil, error)
            }
            do {
                guard let unwrappedData = data else {
                    //let jsonDictionary = try JSONSerialization.jsonObject(with: unwrappedData, options: []) as? [AnyObject] else {
                    completion(nil, CustomError.EmptyData)
                    return
                }
                let object = try JSONDecoder().decode(T.self, from: unwrappedData)
                completion(object, nil)
            } catch {
                completion(nil, CustomError.UnhandledError)
            }
        }
        task.resume()
    }
}
