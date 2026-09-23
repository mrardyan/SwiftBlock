import Foundation

public struct PolylineCoordinate: Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Google / Mapbox Encoded Polyline Algorithm (lossy variable-length ASCII encoding for GPS paths).
public enum __MODULE_NAME__: Sendable {
    /// Decodes an encoded polyline string into an array of `PolylineCoordinate` points.
    /// - Parameters:
    ///   - encodedString: The compressed polyline ASCII string.
    ///   - precision: Coordinate precision (default: 1e5 for 5 decimal places, Mapbox/Google default).
    public static func decode(_ encodedString: String, precision: Double = 1e5) -> [PolylineCoordinate] {
        var coordinates: [PolylineCoordinate] = []
        var index = encodedString.startIndex
        let count = encodedString.count

        var lat = 0
        var lon = 0

        while index < encodedString.endIndex {
            var b: Int
            var shift = 0
            var result = 0

            repeat {
                guard index < encodedString.endIndex else { return coordinates }
                b = Int(encodedString[index].asciiValue ?? 0) - 63
                index = encodedString.index(after: index)
                result |= (b & 0x1f) << shift
                shift += 5
            } while b >= 0x20

            let deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            lat += deltaLat

            shift = 0
            result = 0

            repeat {
                guard index < encodedString.endIndex else { return coordinates }
                b = Int(encodedString[index].asciiValue ?? 0) - 63
                index = encodedString.index(after: index)
                result |= (b & 0x1f) << shift
                shift += 5
            } while b >= 0x20

            let deltaLon = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            lon += deltaLon

            coordinates.append(PolylineCoordinate(
                latitude: Double(lat) / precision,
                longitude: Double(lon) / precision
            ))
        }

        return coordinates
    }

    /// Encodes an array of `PolylineCoordinate` points into a compressed polyline string.
    public static func encode(_ coordinates: [PolylineCoordinate], precision: Double = 1e5) -> String {
        var result = ""
        var prevLat = 0
        var prevLon = 0

        for coord in coordinates {
            let lat = Int(round(coord.latitude * precision))
            let lon = Int(round(coord.longitude * precision))

            encodeValue(lat - prevLat, into: &result)
            encodeValue(lon - prevLon, into: &result)

            prevLat = lat
            prevLon = lon
        }

        return result
    }

    private static func encodeValue(_ value: Int, into result: inout String) {
        var v = value < 0 ? ~(value << 1) : (value << 1)
        while v >= 0x20 {
            let charCode = (0x20 | (v & 0x1f)) + 63
            if let scalar = UnicodeScalar(charCode) {
                result.append(Character(scalar))
            }
            v >>= 5
        }
        if let scalar = UnicodeScalar(v + 63) {
            result.append(Character(scalar))
        }
    }
}
