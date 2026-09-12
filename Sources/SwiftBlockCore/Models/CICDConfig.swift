import Foundation

public enum CICDProvider: String, Codable, CaseIterable {
    case githubActions = "github"
    case gitlabCI = "gitlab"
    case bitrise = "bitrise"
    case xcodeCloud = "xcodecloud"
    case none = "none"

    public var title: String {
        switch self {
        case .githubActions: return "GitHub Actions (.github/workflows/ci.yml)"
        case .gitlabCI: return "GitLab CI (.gitlab-ci.yml)"
        case .bitrise: return "Bitrise (bitrise.yml)"
        case .xcodeCloud: return "Xcode Cloud (ci_scripts/ci_post_clone.sh)"
        case .none: return "None (Skip CI/CD Setup)"
        }
    }
}

public struct CICDConfig: Codable, Equatable {
    public var provider: CICDProvider

    public init(provider: CICDProvider = .githubActions) {
        self.provider = provider
    }
}
