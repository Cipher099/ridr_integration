//
//  ErrorModel.swift
//  RIDRIntegration
//
//  Created by Burton Wevers on 2018/07/03.
//  Copyright © 2018 ZATools. All rights reserved.
//

import Foundation

enum CustomError: Error {
    case UnparsableData
    case EmptyData
    case InvalidURL
    case UnhandledError
}
