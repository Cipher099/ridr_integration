//
//  Helpers.swift
//  RIDRIntegration
//
//  Created by Burton Wevers on 2018/06/06.
//  Copyright © 2018 ZATools. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

public class Helper {
    /**
     Informs users of their location services being disabled and that enabling it
     will give the user a better quality of data
     */
    class func openSettingsForPermissionChange (viewController: UIViewController) {
        let alertController = UIAlertController(
            title: "Location Access Disabled",
            message: "In order to get better data and notification served to you, please open this app's settings and set location access to 'Always'.",
            preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Open Settings", style: .default) { (action) in
            if let url = URL(string:UIApplicationOpenSettingsURLString) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: ["":""], completionHandler: nil)
                } else {
                    // Fallback on earlier versions
                }
            }
        })
        viewController.present(alertController, animated: true, completion: nil)
    }
}

extension UserDefaults {
    /// A parameter to disable user location updates
    var disableLocationUpdates: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "disableLocationUpdates")
        }
        set {
            UserDefaults.standard.set(true, forKey: "disableLocationUpdates")
        }
    }
    
    /// A stored from location
    var fromLocation: CLLocation{
        get {
            return UserDefaults.standard.object(forKey: "fromLocation") as! CLLocation
        }
        set {
            UserDefaults.standard.set(nil, forKey: "fromLocation")
        }
    }
    
    /// A stored to location
    var toLocation: CLLocation {
        get {
            return UserDefaults.standard.object(forKey: "toLocation") as! CLLocation
        }
        set {
            UserDefaults.standard.set(nil, forKey: "toLocation")
        }
    }
    
}

extension BinaryInteger {
    var degreesToRadians: CGFloat { return CGFloat(Int(self)) * .pi / 180 }
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

public extension CLLocation{
    
    func DegreesToRadians(_ degrees: Double ) -> Double {
        return degrees * .pi / 180
    }
    
    func RadiansToDegrees(_ radians: Double) -> Double {
        return radians * 180 / .pi
    }
    
    
    func bearingToLocationRadian(_ destinationLocation:CLLocation) -> Double {
        
        let lat1 = DegreesToRadians(self.coordinate.latitude)
        let lon1 = DegreesToRadians(self.coordinate.longitude)
        
        let lat2 = DegreesToRadians(destinationLocation.coordinate.latitude);
        let lon2 = DegreesToRadians(destinationLocation.coordinate.longitude);
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        let radiansBearing = atan2(y, x)
        
        return radiansBearing
    }
    
    func bearingToLocationDegrees(destinationLocation:CLLocation) -> Double{
        return   RadiansToDegrees(bearingToLocationRadian(destinationLocation))
    }
}
