//
//  RIDRLocationManager.swift
//  RIDRIntegration
//
//  Created by Burton Wevers on 2018/06/06.
//  Copyright © 2018 ZATools. All rights reserved.
//

import Foundation
import CoreLocation
import GEOSwift

public var locManager = LocationManager()

public class LocationManager: NSObject {
    /// The location manager used by this library
    public fileprivate(set) var locManager: CLLocationManager!
    
    /// The heading parameter
    fileprivate var lastHeading: CLHeading?
    
    /// A static value for region detection
    fileprivate let radius: Double = 200
    
    private var route: Route?
    
    override init() {
        super.init()
        locManager = CLLocationManager()
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        locManager.delegate = self
        DispatchQueue.main.async {
            /// Keep an eye on the notification to notify a user why it's happening
            self.locManager.requestAlwaysAuthorization()
        }
        locManager.startUpdatingLocation()
        locManager.startUpdatingHeading()
        if let lastLocation = locManager.location {
            // Acquire and setup geofencing locations
            R.getClosestStations(location: lastLocation.coordinate,
                                 stations: { data in
                                    self.removeAllRegions()
                                    let coordinates = CLLocationCoordinate2D()
                                    let identifier = ""
                                    self.addRegion(location: coordinates, radius: radius, identifier: identifier)
            })
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // Send location information to the server to provide station numbers
        guard let circularRegion = region as? CLCircularRegion else {
            manager.stopUpdatingLocation()
            return
        }
        R.sendLocation(location: CLLocation(latitude: circularRegion.center.latitude,
                                            longitude: circularRegion.center.longitude), isEntering: true)
        R.acquireRoute(stationIdentifier: region.identifier, data: { dictionary in
            self.route = Route.createRoute(dictionary)
        })
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // Determine if the user can be utilised as a beacon for other's using myciti
        guard let circularRegion = region as? CLCircularRegion else {
            manager.stopUpdatingLocation()
            return
        }
        // Disable location manager if can't be used as a beacon
        R.sendLocation(location: CLLocation(latitude: circularRegion.center.latitude,
                                            longitude: circularRegion.center.longitude), isEntering: false)
        // Acquire and setup geofencing locations
        R.getClosestStations(location: circularRegion.center,
                             stations: { data in
                                self.removeAllRegions()
                                let coordinates = CLLocationCoordinate2D()
                                let identifier = ""
                                self.addRegion(location: coordinates, radius: radius, identifier: identifier)
        })
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Don't really use this for anything except showing some information about issues
        guard let error = error as? CLError else { return }
        print(error.code)
        switch error.code {
        case .locationUnknown:
            print("Location Unknown")
            break
        case .denied:
            print("Location Services Denied")
            break
        case .network:
            print("Network error occurred")
            break
        case .headingFailure:
            print("Couldn't acquire heading information")
            break
        case .rangingUnavailable: break
        default: break
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let lastLocation = locations.first else { return }
        if let route = self.route, route.determineBeacon(Locations: locations) {
            let snappedLocation = route.snapToRoute(lastLocation)
            R.sendLocation(location: snappedLocation!, heading: self.lastHeading)
            if UIApplication.shared.applicationState == .active {
                manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                manager.activityType = CLActivityType.automotiveNavigation
                manager.pausesLocationUpdatesAutomatically = true
            } else {
                manager.desiredAccuracy = kCLLocationAccuracyKilometer
                manager.activityType = CLActivityType.otherNavigation
                manager.pausesLocationUpdatesAutomatically = false
            }
        }
        // Should we really stop location updates though?
        manager.stopUpdatingLocation()
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        print("HEADING ACCU: \(newHeading.headingAccuracy), MAGNETIC HEADING: \(newHeading.magneticHeading), TRUE HEADING: \(newHeading.trueHeading)")
        print("X: \(newHeading.x), Y: \(newHeading.y), Z: \(newHeading.z)")
        self.lastHeading = newHeading
    }
    
    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        // TODO: Notify server that there was an error monitoring a region
        // Get the current variable data for the error
        guard let clError = error as? CLError else { return }
        guard let circularRegion = region as? CLCircularRegion else {
            manager.stopUpdatingLocation()
            return
        }
        R.sendLocation(location: CLLocation(latitude: circularRegion.center.latitude,
                                            longitude: circularRegion.center.longitude), isEntering: false)
        manager.stopUpdatingLocation()
        switch clError.code {
        case .regionMonitoringDenied, .regionMonitoringFailure:
            break
        default: break
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locManager.startUpdatingLocation()
            break
        case .denied, .restricted, .notDetermined:
//            let notifName = NSNotification.Name(rawValue: "permission")
//            NotificationCenter.default.post(name: notifName, object: nil, userInfo: nil)
//            Helper.openSettingsForPermissionChange(viewController: )
            break
        }
    }
}

/**
 Extension for the helper function for adding/removing geofencing locations
 */
extension LocationManager {
    // NOTE: Geofencing registering point is limited to 20
    // NOTE: Call requestStateForRegion(_:) if a user is already in a CLCircularRegion
    func region(withNotification notification: GeoLocation) -> CLCircularRegion {
        let region = CLCircularRegion(center: notification.coordinate, radius: notification.radius, identifier: notification.identifier)
        region.notifyOnEntry = (notification.eventType == .onEntry)
        region.notifyOnExit = !region.notifyOnEntry
        return region
    }
    
    func addRegion(location: CLLocationCoordinate2D, radius: Double, identifier: String, note: String? = nil) {
        let clampedRadius = min(radius, locManager.maximumRegionMonitoringDistance)
        let notification = GeoLocation(coordinate: location, radius: clampedRadius, identifier: identifier, note: note, eventType: .onEntry)
        self.startMonitoring(notification: notification)  // Should probably remove this eventually
    }
    
    public func removeRegion(identifier: String) {
        if let selectedRegion = locManager.monitoredRegions.first(where: { (region) -> Bool in
            return region.identifier == identifier
        }) {
            locManager.stopMonitoring(for: selectedRegion)
        }
    }
    
    public func removeAllRegions () {
        locManager.monitoredRegions.forEach { (region) in
            locManager.stopMonitoring(for: region)
        }
    }
    
    private func startMonitoring (notification: GeoLocation?) {
        if (!CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)) {
            // Show alert here : Geofencing is not supported on this device!
            return
        }
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            // Show alert: You geolocation is sved but will only be activiated
            // once you grant geolocation permission
        }
        let region = self.region(withNotification: notification!)
        locManager?.startMonitoring(for: region)
    }
    
    func stopMonitoring (notification: GeoLocation) {
        guard let manager = locManager else { return }
        for region in manager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion,
                circularRegion.identifier == notification.identifier else { continue }
            manager.stopMonitoring(for: circularRegion)
        }
    }
}