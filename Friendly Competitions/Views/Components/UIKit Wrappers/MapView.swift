import MapKit
import UIKit
import SwiftUI

struct MapView: UIViewRepresentable {

    @Binding var coordinates: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isZoomEnabled = false
        mapView.isRotateEnabled = false
        mapView.showsCompass = false
        mapView.delegate = context.coordinator
        update(mapView: mapView)
        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        update(mapView: view)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        private let parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }
    }

    private func update(mapView: MKMapView) {
        mapView.setCenter(coordinates, animated: false)
        let camera = MKMapCamera()
        camera.centerCoordinate = coordinates
//        camera.centerCoordinateDistance = distance
//        camera.heading = flipped ? 180 : 0
        mapView.setCamera(camera, animated: false)
    }
}
