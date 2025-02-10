//
//  MapViewModel.swift
//  RapidoDriverSimulation
//
//  Created by Tilak Shakya on 14/09/24.
//

import MapKit

/// ViewModel for managing the map and driver movement.
class MapViewModel: NSObject, ObservableObject {
    /// The current location of the driver.
    @Published var driverLocation: CLLocationCoordinate2D?
    /// The route points for the driver to follow.
    @Published var route: [RoutePoint] = []
    
    private var timer: Timer?
    private var currentRouteIndex = 0
    
    /// Sets up the route with predefined coordinates.
    func setupRoute() {
        route = [
            RoutePoint(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)),
            RoutePoint(coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)),
            RoutePoint(coordinate: CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.3994))
        ]
        driverLocation = route.first?.coordinate
    }
    
    /// Starts the driver's movement along the route.
    func startDriverMovement() {
        guard !route.isEmpty else { return }
        
        currentRouteIndex = 0
        driverLocation = route[currentRouteIndex].coordinate
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDriverPosition()
        }
    }
    
    /// Updates the driver's position along the route.
    private func updateDriverPosition() {
        guard currentRouteIndex < route.count - 1 else {
            timer?.invalidate()
            return
        }
        
        currentRouteIndex += 1
        driverLocation = route[currentRouteIndex].coordinate
    }
    
    /// Stops the driver's movement.
    func stopDriverMovement() {
        timer?.invalidate()
    }
}
