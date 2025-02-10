//
//  MapViewController.swift
//  RapidoDriverSimulation
//
//  Created by Tilak Shakya on 15/09/24.
//

import UIKit
import Combine
import MapKit
import CoreLocation

/// A view controller that manages the map view and driver movement.
class MapViewController: UIViewController {
    
    // MARK: - Properties
    /// The map view to display the map.
    private var mapView: MKMapView!
    
    /// Button to start the driver's movement.
    private var startButton: UIButton!
    
    /// ViewModel for managing map data.
    private let viewModel = MapViewModel()
    
    /// For Combine subscriptions.
    private var cancellables: Set<AnyCancellable> = []
    
    /// Annotation for the driver on the map.
    private var driverAnnotation: MKPointAnnotation?
    
    /// Location manager for handling location updates.
    private let locationManager = CLLocationManager()
    
    /// Called after the controller's view is loaded into memory.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMapView() // Set up the map view
        setupLocationManager() // Set up the location manager
        setupStartButton() // Set up the start button
        setupBindings() // Set up bindings for data updates
        
        viewModel.setupRoute() // Initialize the route in the ViewModel
        drawInitialRoute() // Draw the initial route on the map
    }
    
    // MARK: - Setup Methods
    
    /// Sets up the map view with necessary configurations.
    private func setupMapView() {
        mapView = MKMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.isRotateEnabled = true
        mapView.isScrollEnabled = true
        mapView.isZoomEnabled = true
        view.addSubview(mapView)
    }
    
    /// Sets up the location manager with necessary configurations.
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Sets up the start button with its properties and action.
    private func setupStartButton() {
        startButton = UIButton(frame: CGRect(x: 20, y: view.bounds.height - 60, width: 100, height: 40))
        startButton.setTitle("Start", for: .normal)
        startButton.backgroundColor = .blue
        startButton.layer.cornerRadius = 12
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        view.addSubview(startButton)
    }
    
    /// Sets up bindings to observe changes in the driver's location.
    private func setupBindings() {
        viewModel.$driverLocation
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] location in
                self?.updateDriverAnnotation(with: location) // Update the driver annotation when location changes
            }
            .store(in: &cancellables)
    }
    
    /// Centers the map on the user's current location.
    private func centerMapOnUserLocation() {
        if let userLocation = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: userLocation, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
        }
    }
    
    /// Draws the initial route on the map.
    private func drawInitialRoute() {
        let coordinates = viewModel.route.map { $0.coordinate }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
        
        if let firstCoordinate = coordinates.first {
            let region = MKCoordinateRegion(center: firstCoordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
            mapView.setRegion(region, animated: true) // Set the map's visible region
        }
    }
    
    /// Action triggered when the start button is tapped.
    @objc private func startButtonTapped() {
        viewModel.startDriverMovement() // Start the driver's movement
    }
    
    /// Updates the driver's annotation on the map with the new location.
    private func updateDriverAnnotation(with location: CLLocationCoordinate2D) {
        if driverAnnotation == nil {
            driverAnnotation = MKPointAnnotation() // Create a new annotation if it doesn't exist
            mapView.addAnnotation(driverAnnotation!)
        }
        
        UIView.animate(withDuration: 1.0) {
            self.driverAnnotation?.coordinate = location // Update the annotation's coordinate
            self.mapView.setCenter(location, animated: true) // Center the map on the new location
        }
    }
    
    /// Resizes the given image to the target size.
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let scaleFactor = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image // Return the resized image or the original if resizing fails
    }
}

extension MapViewController: CLLocationManagerDelegate {
    /// Called when the authorization status for location services changes.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            DispatchQueue.main.async {
                self.locationManager.startUpdatingLocation()
                self.centerMapOnUserLocation()
            }
            
        case .denied, .restricted:
            // Handle denied or restricted access
            print("Location access denied or restricted")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    /// Called when the location manager receives updated location data.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            self.mapView.setRegion(region, animated: true)
            self.locationManager.stopUpdatingLocation()
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    /// Provides the renderer for the overlay on the map.
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .blue
            renderer.lineWidth = 4.0
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    /// Provides the view for the annotation on the map.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil // Do not show a view for the user's location
        }
        
        let identifier = "DriverAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = false
        } else {
            annotationView?.annotation = annotation
        }
        
        if let image = UIImage(named: "bike") {
            let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 65, height: 65))
            annotationView?.image = resizedImage // Set the annotation's image
        }
        
        return annotationView
    }
}

