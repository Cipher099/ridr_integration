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
import GEOSwift

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
            return UserDefaults.standard.bool(forKey: "")
        }
        set {
            UserDefaults.standard.set(true, forKey: "")
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
