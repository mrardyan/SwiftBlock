import Foundation

public struct GeoPoint: Equatable, Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Geodesic calculations engine (Haversine formula, initial/final bearings, compass directions, and destination points).
public enum __MODULE_NAME__: Sendable {
    public static let earthRadiusMeters: Double = 6_371_000.0

    /// Calculates the great-circle distance in meters between two GPS coordinates using the Haversine formula.
    public static func distance(from origin: GeoPoint, to destination: GeoPoint) -> Double {
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

    /// Computes the initial bearing (forward azimuth in degrees 0°..<360°) from origin to destination.
    public static func bearing(from origin: GeoPoint, to destination: GeoPoint) -> Double {
        let lat1Rad = origin.latitude * .pi / 180.0
        let lat2Rad = destination.latitude * .pi / 180.0
        let deltaLonRad = (destination.longitude - origin.longitude) * .pi / 180.0

        let y = sin(deltaLonRad) * cos(lat2Rad)
        let x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(deltaLonRad)
        let radians = atan2(y, x)
        let degrees = radians * 180.0 / .pi

        return fmod((degrees + 360.0), 360.0)
    }

    /// Converts a numerical bearing in degrees to a standard 8-wind or 16-wind compass direction (e.g. "N", "NE", "SSW").
    public static func compassHeading(forBearing degrees: Double) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let normalized = fmod((degrees + 360.0), 360.0)
        let index = Int(round(normalized / 22.5)) % 16
        return directions[index]
    }

    /// Calculates destination coordinate given a starting point, distance in meters, and bearing in degrees.
    public static func destinationPoint(
        from origin: GeoPoint,
        distanceMeters: Double,
        bearingDegrees: Double
    ) -> GeoPoint {
        let angularDistance = distanceMeters / earthRadiusMeters
        let bearingRad = bearingDegrees * .pi / 180.0

        let lat1Rad = origin.latitude * .pi / 180.0
        let lon1Rad = origin.longitude * .pi / 180.0

        let lat2Rad = asin(
            sin(lat1Rad) * cos(angularDistance) +
            cos(lat1Rad) * sin(angularDistance) * cos(bearingRad)
        )

        let lon2Rad = lon1Rad + atan2(
            sin(bearingRad) * sin(angularDistance) * cos(lat1Rad),
            cos(angularDistance) - sin(lat1Rad) * sin(lat2Rad)
        )

        let lat2 = lat2Rad * 180.0 / .pi
        let lon2 = fmod((lon2Rad * 180.0 / .pi) + 540.0, 360.0) - 180.0

        return GeoPoint(latitude: lat2, longitude: lon2)
    }
}
