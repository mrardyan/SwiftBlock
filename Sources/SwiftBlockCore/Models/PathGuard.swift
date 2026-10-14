import Foundation

public enum PathGuard {
    /// Canonicalizes a path for consistent prefix comparison on macOS,
    /// handling Darwin's `/private/var` vs `/var` and `/private/tmp` vs `/tmp` symlink duality.
    private static func canonicalize(_ path: String) -> String {
        var standardized = URL(fileURLWithPath: path).standardizedFileURL.path
        if standardized.hasPrefix("/private/") {
            standardized = String(standardized.dropFirst(8)) // strip "/private"
        }
        return standardized
    }

    /// Checks whether `targetPath` resolves safely within `rootPath`.
    /// Handles symlinks (e.g. macOS /tmp -> /private/tmp) and blocks ".." escapes.
    public static func isSafe(targetPath: String, withinRoot rootPath: String) -> Bool {
        let isAbsolute = (targetPath as NSString).isAbsolutePath
        if isAbsolute {
            let target = canonicalize(targetPath)
            let root = canonicalize(rootPath)
            return target == root || target.hasPrefix(root + "/")
        } else {
            if (targetPath as NSString).pathComponents.contains("..") {
                return false
            }
            let fullPath = (rootPath as NSString).appendingPathComponent(targetPath)
            let target = canonicalize(fullPath)
            let root = canonicalize(rootPath)
            return target == root || target.hasPrefix(root + "/")
        }
    }
}
