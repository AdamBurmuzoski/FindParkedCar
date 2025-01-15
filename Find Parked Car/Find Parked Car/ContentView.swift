import SwiftUI
import MapKit
import UIKit

@main
struct Find_Parked_CarApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @ObservedObject var locationManager = LocationManager()
    @State private var savedLocation: CLLocationCoordinate2D?
    @State private var mapCenterCoordinate: CLLocationCoordinate2D?
    @State private var annotations: [IdentifiablePointAnnotation] = []
    @AppStorage("mapTypeRawValue") private var mapTypeRawValue: Int = Int(MKMapType.standard.rawValue)
    @State private var mapType: MKMapType = .standard
    @State private var selectedAnnotation: IdentifiablePointAnnotation?
    
    var body: some View {
        ZStack {
            CustomMapView(centerCoordinate: $mapCenterCoordinate, annotations: $annotations, mapType: $mapType, selectedAnnotation: $selectedAnnotation)
            
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    VStack {
                        Button(action: {
                            mapType = (mapType == .standard) ? .hybridFlyover : .standard
                            mapTypeRawValue = Int(mapType.rawValue)
                        }) {
                            Image(systemName: "globe")
                                .font(.largeTitle)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 3)
                        Button(action: {
                            if let location = locationManager.lastKnownLocation {
                                mapCenterCoordinate = location
                            }
                        }) {
                            Image(systemName: "location.fill")
                                .font(.largeTitle)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                                .foregroundColor(.blue)
                        }
                        .padding(.trailing, 3)
                    }
                    .padding(.bottom, 500)
                }
                
                HStack {
                    Button(" Save ") {
                        if let location = locationManager.lastKnownLocation {
                            savedLocation = location
                            mapCenterCoordinate = location
                            UserDefaults.standard.set([
                                "latitude": location.latitude,
                                "longitude": location.longitude
                            ], forKey: "savedLocation")
                            
                            let newAnnotation = IdentifiablePointAnnotation()
                            newAnnotation.coordinate = location
                            annotations.append(newAnnotation)
                            
                            // Automatically select and highlight the new pin
                            selectedAnnotation = newAnnotation
                            
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.prepare()
                            generator.impactOccurred()
                        }
                    }
                    .padding()
                    .font(.largeTitle)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button(" Reset ") {
                        savedLocation = nil
                        UserDefaults.standard.removeObject(forKey: "savedLocation")
                        annotations.removeAll()
                        selectedAnnotation = nil
                        
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.prepare()
                        generator.impactOccurred()
                    }
                    .padding()
                    .font(.largeTitle)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button(" Map ") {
                        openMapsWithDirections()
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.prepare()
                        generator.impactOccurred()
                    }
                    .padding()
                    .font(.largeTitle)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.bottom, 45)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            mapType = MKMapType(rawValue: UInt(mapTypeRawValue)) ?? .standard
            mapCenterCoordinate = locationManager.lastKnownLocation // Initialize mapCenterCoordinate on appear
            if let locationData = UserDefaults.standard.dictionary(forKey: "savedLocation"),
               let latitude = locationData["latitude"] as? CLLocationDegrees,
               let longitude = locationData["longitude"] as? CLLocationDegrees {
                savedLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                
                let newAnnotation = IdentifiablePointAnnotation()
                newAnnotation.coordinate = savedLocation!
                annotations.append(newAnnotation)
                
                // Automatically select and highlight the new pin
                selectedAnnotation = newAnnotation
            }
        }
    }
    
    func openMapsWithDirections() {
        guard let selectedLocation = selectedAnnotation?.coordinate else { return }
        let placemark = MKPlacemark(coordinate: selectedLocation)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "My Parked Car"
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMaps(launchOptions: launchOptions)
    }
}

struct CustomMapView: UIViewRepresentable {
    @Binding var centerCoordinate: CLLocationCoordinate2D?
    @Binding var annotations: [IdentifiablePointAnnotation]
    @Binding var mapType: MKMapType
    @Binding var selectedAnnotation: IdentifiablePointAnnotation?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleLongPressGesture(_:)))
        mapView.addGestureRecognizer(longPressGesture)
        
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        view.mapType = mapType
        view.removeAnnotations(view.annotations)
        view.addAnnotations(annotations)
        if let center = centerCoordinate {
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            view.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        
        init(_ parent: CustomMapView) {
            self.parent = parent
        }
        
        @objc func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .ended {
                let mapView = gesture.view as! MKMapView
                let touchLocation = gesture.location(in: mapView)
                let tappedCoordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
                
                // Create a new annotation at the tapped location
                let newAnnotation = IdentifiablePointAnnotation()
                newAnnotation.coordinate = tappedCoordinate
                parent.annotations.append(newAnnotation)
                
                // Automatically select and highlight the new pin
                parent.selectedAnnotation = newAnnotation
                
                // Provide tactile feedback after the pin is dropped
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let annotation = annotation as? IdentifiablePointAnnotation {
                var markerView = mapView.dequeueReusableAnnotationView(withIdentifier: "marker") as? MKMarkerAnnotationView
                if markerView == nil {
                    markerView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "marker")
                } else {
                    markerView?.annotation = annotation
                }
                
                // Set the marker color based on whether it's selected
                if annotation == parent.selectedAnnotation {
                    markerView?.markerTintColor = .blue // Selected pin will be blue
                } else {
                    markerView?.markerTintColor = .red // Default color for other pins
                    markerView?.glyphText = nil
                }
                
                markerView?.canShowCallout = true
                
                // Ensure the glyph is visible, even in satellite mode
                if parent.mapType == .satellite {
                    markerView?.glyphTintColor = .white // Ensure visibility in satellite mode
                }
                
                return markerView
            }
            return nil
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation as? IdentifiablePointAnnotation {
                // Update the selected pin
                parent.selectedAnnotation = annotation
                
                // Provide tactile feedback when a pin is selected
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
            }
        }
    }
}

class IdentifiablePointAnnotation: MKPointAnnotation, Identifiable {}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var lastKnownLocation: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastKnownLocation = locations.first?.coordinate
    }
}
