import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {
    @Binding var centerCoordinate: CLLocationCoordinate2D?
    @Binding var annotations: [IdentifiablePointAnnotation]
    @Binding var selectedAnnotation: IdentifiablePointAnnotation? // To track selected annotation
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        view.removeAnnotations(view.annotations)
        view.addAnnotations(annotations)
        
        if let selectedAnnotation = selectedAnnotation {
            if let annotationView = view.view(for: selectedAnnotation) {
                annotationView.pinTintColor = .blue
            }
        }
        
        if let center = centerCoordinate {
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            view.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation as? IdentifiablePointAnnotation {
                parent.selectedAnnotation = annotation // Set the selected annotation
            }
        }

        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            if let annotation = view.annotation as? IdentifiablePointAnnotation {
                if parent.selectedAnnotation == annotation {
                    parent.selectedAnnotation = nil // Deselect annotation
                }
            }
        }
    }
}
