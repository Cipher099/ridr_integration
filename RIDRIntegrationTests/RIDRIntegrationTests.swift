//
//  RIDRIntegrationTests.swift
//  RIDRIntegrationTests
//
//  Created by Burton Wevers on 2018/06/06.
//  Copyright © 2018 ZATools. All rights reserved.
//

import XCTest
import CoreLocation
@testable import RIDRIntegration

class RIDRIntegrationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAcquireRoute() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        // 1. Define an expectation
        let expect = expectation(description: "SomeService does stuff and runs the callback closure")
        
        // 2. Exercise the asynchronous code
        R.acquireRoute(stationIdentifier: "random string", data: { data in
            XCTAssert(data.count > 0)
            
            // Don't forget to fulfill the expectation in the async callback
            expect.fulfill()
        })
        
        // 3. Wait for the expectation to be fulfilled
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    
    func testClosestStation () {
        
        // 1. Define an expectation
        let expect = expectation(description: "SomeService does stuff and runs the callback closure")
        let location = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        
        // 2. Exercise the asynchronous code
        R.getClosestStations(location: location, ResultCount: 10) { (data) in
            print(data)
            XCTAssert(data.count > 0)
            
            // Don't forget to fulfill the expectation in the async callback
            expect.fulfill()
        }
        
        // 3. Wait for the expectation to be fulfilled
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    
    func testRouteGenerationBad () {
        // 1. Define an expectation
        let expect = expectation(description: "SomeService does stuff and runs the callback closure")
        
        // 2. Exercise the asynchronous code
        R.acquireRoute(stationIdentifier: "random string", data: { dictionary in
            let route = Route.createRoute([:])
            XCTAssertFalse(route.isValid)
            
            // Don't forget to fulfill the expectation in the async callback
            expect.fulfill()
        })
        
        // 3. Wait for the expectation to be fulfilled
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    
    func testRouteGeneration () {
        
        // 1. Define an expectation
        let expect = expectation(description: "SomeService does stuff and runs the callback closure")
        
        // 2. Exercise the asynchronous code
        R.acquireRoute(stationIdentifier: "random string", data: { dictionary in
            let route = Route.createRoute(dictionary)
            XCTAssert(route.isValid)
            
            // Don't forget to fulfill the expectation in the async callback
            expect.fulfill()
        })
        
        // 3. Wait for the expectation to be fulfilled
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
