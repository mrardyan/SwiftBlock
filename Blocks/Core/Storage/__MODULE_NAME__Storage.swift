import Foundation

public protocol __MODULE_NAME__StorageProtocol {
    func save<T: Codable>(_ item: T, forKey key: String) throws
    func load<T: Codable>(forKey key: String, as type: T.Type) throws -> T?
    func remove(forKey key: String)
}

public final class __MODULE_NAME__Storage: __MODULE_NAME__StorageProtocol {
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func save<T: Codable>(_ item: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(item)
        userDefaults.set(data, forKey: key)
    }

    public func load<T: Codable>(forKey key: String, as type: T.Type) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }

    public func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
}
