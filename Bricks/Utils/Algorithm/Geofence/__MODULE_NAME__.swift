import Foundation

public struct GeofencePoint: Equatable, Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct CircularGeofence: Sendable {
    public let center: GeofencePoint
    public let radiusMeters: Double

    public init(center: GeofencePoint, radiusMeters: Double) {
        self.center = center
        self.radiusMeters = max(0, radiusMeters)
    }

    public func contains(_ point: GeofencePoint) -> Bool {
        let distance = __MODULE_NAME__.haversineDistance(from: center, to: point)
        return distance <= radiusMeters
    }
}

public struct PolygonGeofence: Sendable {
    public let vertices: [GeofencePoint]

    public init(vertices: [GeofencePoint]) {
        self.vertices = vertices
    }

    /// Evaluates if `point` is inside the polygon using the Ray-Casting algorithm ($O(n)$).
    public func contains(_ point: GeofencePoint) -> Bool {
        guard vertices.count >= 3 else { return false }

        var isInside = false
        var j = vertices.count - 1

        for i in 0..<vertices.count {
            let pi = vertices[i]
            let pj = vertices[j]

            // Check if horizontal ray from point crosses the edge between pj and pi
            if ((pi.latitude > point.latitude) != (pj.latitude > point.latitude)) &&
                (point.longitude < (pj.longitude - pi.longitude) * (point.latitude - pi.latitude) / (pj.latitude - pi.latitude) + pi.longitude) {
                isInside.toggle()
            }
            j = i
        }

        return isInside
    }
}

/// Geofencing boundary validation engine (Ray-Casting Point-in-Polygon & Circular Radius).
public enum __MODULE_NAME__: Sendable {
    /// Tests if a GPS coordinate is inside an arbitrary polygon defined by `vertices`.
    public static func isPointInPolygon(_ point: GeofencePoint, vertices: [GeofencePoint]) -> Bool {
        PolygonGeofence(vertices: vertices).contains(point)
    }

    /// Tests if a GPS coordinate is within `radiusMeters` of `center`.
    public static func isPointInCircle(_ point: GeofencePoint, center: GeofencePoint, radiusMeters: Double) -> Bool {
        CircularGeofence(center: center, radiusMeters: radiusMeters).contains(point)
    }

    public static func haversineDistance(from origin: GeofencePoint, to destination: GeofencePoint) -> Double {
        let earthRadiusMeters: Double = 6_371_000.0

        let lat1Rad = origin.latitude * .pi / 180.0
        let lat2Rad = destination.latitude * .pi / 180.0
        let deltaLatRad = (destination.latitude - origin.latitude) * .pi / 180.0
        let deltaLonRad = (destination.longitude - origin.longitude) * .pi / 180.0

        let a = sin(deltaLatRad / 2.0) * sin(deltaLatRad / 2.0) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLonRad / 2.0) * sin(deltaLonRad / 2.0)

        let c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a))
        return earthRadiusMeters * c
    }
}
