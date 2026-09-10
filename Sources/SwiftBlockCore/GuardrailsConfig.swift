import Foundation

public struct GuardrailsConfig: Codable, Equatable {
    public var swiftlint: Bool
    public var swiftformat: Bool
    public var precommit: Bool
    public var periphery: Bool
    public var gitleaks: Bool
    public var danger: Bool
    public var swiftgen: Bool
    public var licenseplist: Bool

    public init(
        swiftlint: Bool = true,
        swiftformat: Bool = true,
        precommit: Bool = true,
        periphery: Bool = true,
        gitleaks: Bool = true,
        danger: Bool = true,
        swiftgen: Bool = true,
        licenseplist: Bool = true
    ) {
        self.swiftlint = swiftlint
        self.swiftformat = swiftformat
        self.precommit = precommit
        self.periphery = periphery
        self.gitleaks = gitleaks
        self.danger = danger
        self.swiftgen = swiftgen
        self.licenseplist = licenseplist
    }

    public static let all = GuardrailsConfig(
        swiftlint: true,
        swiftformat: true,
        precommit: true,
        periphery: true,
        gitleaks: true,
        danger: true,
        swiftgen: true,
        licenseplist: true
    )

    public static let none = GuardrailsConfig(
        swiftlint: false,
        swiftformat: false,
        precommit: false,
        periphery: false,
        gitleaks: false,
        danger: false,
        swiftgen: false,
        licenseplist: false
    )
}
