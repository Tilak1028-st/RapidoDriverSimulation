//
//  RapidoDriverSimulationTests.swift
//  RapidoDriverSimulationTests
//
//  Created by Tilak Shakya on 15/09/24.
//

import XCTest
import CoreLocation
@testable import RapidoDriverSimulation

final class RapidoDriverSimulationTests: XCTestCase {
    
    var viewModel: MapViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = MapViewModel() // Initialize the ViewModel before each test
    }
    
    override func tearDown() {
        viewModel = nil // Cleanup after each test
        super.tearDown()
    }
    
    
    /// Tests that the route is correctly initialized.
    func testSetupRoute() {
        // Given: Route is not set
        XCTAssertTrue(viewModel.route.isEmpty)
        
        // When: Route is set up
        viewModel.setupRoute()
        
        // Then: Route should contain coordinates
        XCTAssertEqual(viewModel.route.count, 3)
        XCTAssertEqual(viewModel.driverLocation?.latitude, 37.7749)
        XCTAssertEqual(viewModel.driverLocation?.longitude, -122.4194)
    }
    
    /// Tests that driver movement starts and updates as expected.
    func testDriverMovementStarts() {
        // Given: Route is set up
        viewModel.setupRoute()
        
        // When: Start driver movement
        viewModel.startDriverMovement()
        
        // Then: Driver's initial location should be set to the first route point
        XCTAssertEqual(viewModel.driverLocation?.latitude, 37.7749, "Initial driver's latitude should match the first route point")
        XCTAssertEqual(viewModel.driverLocation?.longitude, -122.4194, "Initial driver's longitude should match the first route point")
        
        // Simulate movement by advancing time with a longer timeout and verify the second movement update
        let expectation = XCTestExpectation(description: "Driver moves to the second route point")
        
        
        let expectedTimeout: TimeInterval = 5.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.viewModel.driverLocation?.latitude, 37.7849, "Driver should have moved to the second route point latitude")
            XCTAssertEqual(self.viewModel.driverLocation?.longitude, -122.4094, "Driver should have moved to the second route point longitude")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: expectedTimeout)
    }
    
}
