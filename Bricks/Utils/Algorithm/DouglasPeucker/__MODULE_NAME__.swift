import Foundation

public struct TrackPoint: Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Ramer–Douglas–Peucker (RDP) polyline simplification algorithm.
///
/// Decimates a curve composed of line segments to a similar curve with fewer points,
/// optimizing rendering performance and reducing GPS tracking payload sizes.
public enum __MODULE_NAME__: Sendable {
    /// Simplifies an array of `TrackPoint` coordinates using the Ramer-Douglas-Peucker algorithm.
    /// - Parameters:
    ///   - points: Ordered sequence of GPS route points.
    ///   - tolerance: Maximum perpendicular distance threshold (epsilon) in meters (default: 10.0 meters).
    public static func simplify(_ points: [TrackPoint], tolerance: Double = 10.0) -> [TrackPoint] {
        guard points.count > 2 else { return points }

        var maxDistance: Double = 0.0
        var maxIndex = 0
        let count = points.count

        let start = points[0]
        let end = points[count - 1]

        for i in 1..<(count - 1) {
            let distance = perpendicularDistance(point: points[i], lineStart: start, lineEnd: end)
            if distance > maxDistance {
                maxDistance = distance
                maxIndex = i
            }
        }

        if maxDistance > tolerance {
            let leftSlice = Array(points[0...maxIndex])
            let rightSlice = Array(points[maxIndex..<count])

            let leftSimplified = simplify(leftSlice, tolerance: tolerance)
            let rightSimplified = simplify(rightSlice, tolerance: tolerance)

            return Array(leftSimplified.dropLast()) + rightSimplified
        } else {
            return [start, end]
        }
    }

    /// Computes approximate perpendicular distance in meters from `point` to the line segment between `lineStart` and `lineEnd`.
    private static func perpendicularDistance(point: TrackPoint, lineStart: TrackPoint, lineEnd: TrackPoint) -> Double {
        let lat1 = lineStart.latitude
        let lon1 = lineStart.longitude
        let lat2 = lineEnd.latitude
        let lon2 = lineEnd.longitude
        let pLat = point.latitude
        let pLon = point.longitude

        // Approximate meters per degree latitude and longitude
        let metersPerLat = 111_139.0
        let metersPerLon = 111_139.0 * cos(lat1 * .pi / 180.0)

        let x = (pLon - lon1) * metersPerLon
        let y = (pLat - lat1) * metersPerLat
        let dx = (lon2 - lon1) * metersPerLon
        let dy = (lat2 - lat1) * metersPerLat

        let lineLengthSquared = dx * dx + dy * dy
        if lineLengthSquared == 0 {
            return sqrt(x * x + y * y)
        }

        let t = max(0, min(1, (x * dx + y * dy) / lineLengthSquared))
        let projX = t * dx
        let projY = t * dy

        let distSq = (x - projX) * (x - projX) + (y - projY) * (y - projY)
        return sqrt(distSq)
    }
}
