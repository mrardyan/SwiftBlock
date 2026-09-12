import Foundation

public struct PackagingConfig: Codable, Equatable {
    public var feature: String
    public var core: String

    public init(feature: String = "monolithic", core: String = "spm") {
        self.feature = feature
        self.core = core
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.feature = (try? container.decode(String.self, forKey: .feature)) ?? "monolithic"
            self.core = (try? container.decode(String.self, forKey: .core)) ?? "spm"
        } else if let single = try? decoder.singleValueContainer(),
                  let value = try? single.decode(String.self) {
            self.feature = value
            self.core = value == "spm" ? "spm" : "monolithic"
        } else {
            self.feature = "monolithic"
            self.core = "spm"
        }
    }
}
