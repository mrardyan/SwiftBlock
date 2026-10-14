import Foundation

public struct GeohashBounds: Equatable, Sendable {
    public let minLat: Double
    public let maxLat: Double
    public let minLon: Double
    public let maxLon: Double

    public var centerLat: Double { (minLat + maxLat) / 2.0 }
    public var centerLon: Double { (minLon + maxLon) / 2.0 }
}

public struct GeohashNeighbors: Equatable, Sendable {
    public let north: String
    public let south: String
    public let east: String
    public let west: String
    public let northEast: String
    public let northWest: String
    public let southEast: String
    public let southWest: String

    public var all: [String] {
        [north, south, east, west, northEast, northWest, southEast, southWest]
    }
}

/// Hierarchical spatial index encoding GPS coordinates into base32 Geohash strings.
public enum __MODULE_NAME__: Sendable {
    private static let base32Chars = Array("0123456789bcdefghjkmnpqrstuvwxyz")
    private static let base32Lookup: [Character: Int] = {
        var dict: [Character: Int] = [:]
        for (index, char) in base32Chars.enumerated() {
            dict[char] = index
        }
        return dict
    }()

    /// Encodes (latitude, longitude) into a Geohash string of the specified `precision` (default: 8 chars, ~38m precision).
    public static func encode(latitude: Double, longitude: Double, precision: Int = 8) -> String {
        guard precision > 0 else { return "" }

        var latInterval = (-90.0, 90.0)
        var lonInterval = (-180.0, 180.0)

        var geohash = ""
        var isEvenBit = true
        var bitCount = 0
        var ch = 0

        while geohash.count < precision {
            if isEvenBit {
                let mid = (lonInterval.0 + lonInterval.1) / 2.0
                if longitude >= mid {
                    ch |= (1 << (4 - bitCount))
                    lonInterval.0 = mid
                } else {
                    lonInterval.1 = mid
                }
            } else {
                let mid = (latInterval.0 + latInterval.1) / 2.0
                if latitude >= mid {
                    ch |= (1 << (4 - bitCount))
                    latInterval.0 = mid
                } else {
                    latInterval.1 = mid
                }
            }

            isEvenBit.toggle()

            if bitCount < 4 {
                bitCount += 1
            } else {
                geohash.append(base32Chars[ch])
                bitCount = 0
                ch = 0
            }
        }

        return geohash
    }

    /// Decodes a Geohash string into its bounding box boundaries.
    public static func decode(geohash: String) -> GeohashBounds? {
        let cleanHash = geohash.lowercased()
        guard !cleanHash.isEmpty else { return nil }

        var latInterval = (-90.0, 90.0)
        var lonInterval = (-180.0, 180.0)
        var isEvenBit = true

        for char in cleanHash {
            guard let charVal = base32Lookup[char] else { return nil }

            for bit in (0..<5).reversed() {
                let mask = 1 << bit
                if isEvenBit {
                    let mid = (lonInterval.0 + lonInterval.1) / 2.0
                    if (charVal & mask) != 0 {
                        lonInterval.0 = mid
                    } else {
                        lonInterval.1 = mid
                    }
                } else {
                    let mid = (latInterval.0 + latInterval.1) / 2.0
                    if (charVal & mask) != 0 {
                        latInterval.0 = mid
                    } else {
                        latInterval.1 = mid
                    }
                }
                isEvenBit.toggle()
            }
        }

        return GeohashBounds(
            minLat: latInterval.0,
            maxLat: latInterval.1,
            minLon: lonInterval.0,
            maxLon: lonInterval.1
        )
    }

    /// Calculates the 8 adjacent neighboring geohashes for proximity queries.
    public static func neighbors(for geohash: String) -> GeohashNeighbors? {
        guard let bounds = decode(geohash: geohash) else { return nil }
        let precision = geohash.count

        let latDelta = bounds.maxLat - bounds.minLat
        let lonDelta = bounds.maxLon - bounds.minLon

        let cLat = bounds.centerLat
        let cLon = bounds.centerLon

        let n = encode(latitude: cLat + latDelta, longitude: cLon, precision: precision)
        let s = encode(latitude: cLat - latDelta, longitude: cLon, precision: precision)
        let e = encode(latitude: cLat, longitude: cLon + lonDelta, precision: precision)
        let w = encode(latitude: cLat, longitude: cLon - lonDelta, precision: precision)

        let ne = encode(latitude: cLat + latDelta, longitude: cLon + lonDelta, precision: precision)
        let nw = encode(latitude: cLat + latDelta, longitude: cLon - lonDelta, precision: precision)
        let se = encode(latitude: cLat - latDelta, longitude: cLon + lonDelta, precision: precision)
        let sw = encode(latitude: cLat - latDelta, longitude: cLon - lonDelta, precision: precision)

        return GeohashNeighbors(
            north: n,
            south: s,
            east: e,
            west: w,
            northEast: ne,
            northWest: nw,
            southEast: se,
            southWest: sw
        )
    }
}
