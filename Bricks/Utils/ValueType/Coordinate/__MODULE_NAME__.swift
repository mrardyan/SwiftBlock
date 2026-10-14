import Foundation

/// Errors thrown by geographic coordinate validation.
public enum CoordinateError: Error, Equatable, Sendable {
    case invalidLatitude(Double)
    case invalidLongitude(Double)
}

/// Type-safe geographic coordinate value type representing latitude and longitude.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double?

    public init(latitude: Double, longitude: Double, altitude: Double? = nil) throws {
        guard (-90.0...90.0).contains(latitude) else {
            throw CoordinateError.invalidLatitude(latitude)
        }
        guard (-180.0...180.0).contains(longitude) else {
            throw CoordinateError.invalidLongitude(longitude)
        }
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
    }

    /// Calculates distance in meters to another coordinate using the Haversine formula.
    public func distance(to destination: __MODULE_NAME__) -> Double {
        let earthRadiusMeters = 6_371_000.0

        let lat1Rad = latitude * .pi / 180.0
        let lat2Rad = destination.latitude * .pi / 180.0
        let deltaLatRad = (destination.latitude - latitude) * .pi / 180.0
        let deltaLonRad = (destination.longitude - longitude) * .pi / 180.0

        let a = sin(deltaLatRad / 2.0) * sin(deltaLatRad / 2.0) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLonRad / 2.0) * sin(deltaLonRad / 2.0)

        let c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a))
        return earthRadiusMeters * c
    }
}
