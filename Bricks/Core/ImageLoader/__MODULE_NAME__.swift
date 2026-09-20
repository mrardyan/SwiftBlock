import UIKit

/// Async remote image loader with in-memory caching.
public final class __MODULE_NAME__ {
    public static let shared = __MODULE_NAME__()

    private let session: URLSession
    private let cache: NSCache<NSURL, UIImage>

    public init(session: URLSession = .shared, cacheLimit: Int = 100) {
        self.session = session
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = cacheLimit
        self.cache = cache
    }

    /// Fetches an image for the given URL, returning a cached copy when available.
    public func image(from url: URL) async -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }
        guard let (data, response) = try? await session.data(from: url),
              let image = UIImage(data: data) else {
            return nil
        }
        if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
            cache.setObject(image, forKey: url as NSURL)
        }
        return image
    }

    /// Removes all cached images.
    public func clearCache() {
        cache.removeAllObjects()
    }
}