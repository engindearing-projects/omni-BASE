import Foundation
import Combine
import MapKit

// MARK: - Drawing Store

class DrawingStore: ObservableObject {
    @Published var markers: [MarkerDrawing] = []
    @Published var routes: [RouteDrawing] = []
    @Published var circles: [CircleDrawing] = []
    @Published var polygons: [PolygonDrawing] = []

    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // UserDefaults keys
    private let markersKey = "DrawingStore.markers"
    private let routesKey = "DrawingStore.routes"
    private let circlesKey = "DrawingStore.circles"
    private let polygonsKey = "DrawingStore.polygons"

    init() {
        loadAllDrawings()
    }

    // MARK: - Load Drawings

    func loadAllDrawings() {
        loadMarkers()
        loadRoutes()
        loadCircles()
        loadPolygons()
        print("Loaded drawings - Markers: \(markers.count), Routes: \(routes.count), Circles: \(circles.count), Polygons: \(polygons.count)")
    }

    private func loadMarkers() {
        guard let data = userDefaults.data(forKey: markersKey) else {
            markers = []
            return
        }

        do {
            markers = try decoder.decode([MarkerDrawing].self, from: data)
        } catch {
            print("Failed to load markers: \(error)")
            markers = []
        }
    }

    private func loadRoutes() {
        guard let data = userDefaults.data(forKey: routesKey) else {
            routes = []
            return
        }

        do {
            routes = try decoder.decode([RouteDrawing].self, from: data)
        } catch {
            print("Failed to load routes: \(error)")
            routes = []
        }
    }

    private func loadCircles() {
        guard let data = userDefaults.data(forKey: circlesKey) else {
            circles = []
            return
        }

        do {
            circles = try decoder.decode([CircleDrawing].self, from: data)
        } catch {
            print("Failed to load circles: \(error)")
            circles = []
        }
    }

    private func loadPolygons() {
        guard let data = userDefaults.data(forKey: polygonsKey) else {
            polygons = []
            return
        }

        do {
            polygons = try decoder.decode([PolygonDrawing].self, from: data)
        } catch {
            print("Failed to load polygons: \(error)")
            polygons = []
        }
    }

    // MARK: - Save Drawings

    func saveAllDrawings() {
        saveMarkers()
        saveRoutes()
        saveCircles()
        savePolygons()
    }

    private func saveMarkers() {
        do {
            let data = try encoder.encode(markers)
            userDefaults.set(data, forKey: markersKey)
            print("Saved \(markers.count) markers")
        } catch {
            print("Failed to save markers: \(error)")
        }
    }

    private func saveRoutes() {
        do {
            let data = try encoder.encode(routes)
            userDefaults.set(data, forKey: routesKey)
            print("Saved \(routes.count) routes")
        } catch {
            print("Failed to save routes: \(error)")
        }
    }

    private func saveCircles() {
        do {
            let data = try encoder.encode(circles)
            userDefaults.set(data, forKey: circlesKey)
            print("Saved \(circles.count) circles")
        } catch {
            print("Failed to save circles: \(error)")
        }
    }

    private func savePolygons() {
        do {
            let data = try encoder.encode(polygons)
            userDefaults.set(data, forKey: polygonsKey)
            print("Saved \(polygons.count) polygons")
        } catch {
            print("Failed to save polygons: \(error)")
        }
    }

    // MARK: - Add Drawings

    func addMarker(_ marker: MarkerDrawing) {
        markers.append(marker)
        saveMarkers()
        print("Added marker: \(marker.name)")
    }

    func addRoute(_ route: RouteDrawing) {
        routes.append(route)
        saveRoutes()
        print("Added route: \(route.name)")
    }

    func addCircle(_ circle: CircleDrawing) {
        circles.append(circle)
        saveCircles()
        print("Added circle: \(circle.name)")
    }

    func addPolygon(_ polygon: PolygonDrawing) {
        polygons.append(polygon)
        savePolygons()
        print("Added polygon: \(polygon.name)")
    }

    // MARK: - Update Drawings

    func updateMarker(_ marker: MarkerDrawing) {
        if let index = markers.firstIndex(where: { $0.id == marker.id }) {
            markers[index] = marker
            saveMarkers()
            print("Updated marker: \(marker.name)")
        }
    }

    func updateRoute(_ route: RouteDrawing) {
        if let index = routes.firstIndex(where: { $0.id == route.id }) {
            routes[index] = route
            saveRoutes()
            print("Updated route: \(route.name)")
        }
    }

    func updateCircle(_ circle: CircleDrawing) {
        if let index = circles.firstIndex(where: { $0.id == circle.id }) {
            circles[index] = circle
            saveCircles()
            print("Updated circle: \(circle.name)")
        }
    }

    func updatePolygon(_ polygon: PolygonDrawing) {
        if let index = polygons.firstIndex(where: { $0.id == polygon.id }) {
            polygons[index] = polygon
            savePolygons()
            print("Updated polygon: \(polygon.name)")
        }
    }

    // MARK: - Delete Drawings

    func deleteMarker(_ marker: MarkerDrawing) {
        markers.removeAll { $0.id == marker.id }
        saveMarkers()
        print("Deleted marker: \(marker.name)")
    }

    func deleteRoute(_ route: RouteDrawing) {
        routes.removeAll { $0.id == route.id }
        saveRoutes()
        print("Deleted route: \(route.name)")
    }

    func deleteCircle(_ circle: CircleDrawing) {
        circles.removeAll { $0.id == circle.id }
        saveCircles()
        print("Deleted circle: \(circle.name)")
    }

    func deletePolygon(_ polygon: PolygonDrawing) {
        polygons.removeAll { $0.id == polygon.id }
        savePolygons()
        print("Deleted polygon: \(polygon.name)")
    }

    // MARK: - Clear All

    func clearAllDrawings() {
        markers.removeAll()
        routes.removeAll()
        circles.removeAll()
        polygons.removeAll()
        saveAllDrawings()
        print("Cleared all drawings")
    }

    // MARK: - Get All Overlays

    func getAllOverlays() -> [MKOverlay] {
        var overlays: [MKOverlay] = []

        // Add circles
        for circle in circles {
            overlays.append(circle.createOverlay())
        }

        // Add polygons
        for polygon in polygons {
            overlays.append(polygon.createOverlay())
        }

        // Add routes
        for route in routes {
            overlays.append(route.createOverlay())
        }

        return overlays
    }

    // MARK: - Helper Methods

    func getDrawingColor(for overlay: MKOverlay) -> DrawingColor? {
        // Check circles
        if let circle = overlay as? MKCircle {
            return circles.first {
                let circleOverlay = $0.createOverlay() as? MKCircle
                return circleOverlay?.coordinate.latitude == circle.coordinate.latitude &&
                       circleOverlay?.coordinate.longitude == circle.coordinate.longitude &&
                       circleOverlay?.radius == circle.radius
            }?.color
        }

        // Check polygons
        if let polygon = overlay as? MKPolygon {
            return polygons.first {
                let polygonOverlay = $0.createOverlay() as? MKPolygon
                return polygonOverlay?.pointCount == polygon.pointCount
            }?.color
        }

        // Check routes
        if let polyline = overlay as? MKPolyline {
            return routes.first {
                let routeOverlay = $0.createOverlay() as? MKPolyline
                return routeOverlay?.pointCount == polyline.pointCount
            }?.color
        }

        return nil
    }

    func totalDrawingCount() -> Int {
        return markers.count + routes.count + circles.count + polygons.count
    }
}
