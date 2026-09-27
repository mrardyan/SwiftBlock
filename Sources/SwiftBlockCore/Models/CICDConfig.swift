import Foundation

public enum CICDProvider: String, Codable, CaseIterable {
    case githubActions = "github"
    case gitlabCI = "gitlab"
    case bitrise
    case xcodeCloud = "xcodecloud"
    case none

    public var title: String {
        switch self {
            case .githubActions: "GitHub Actions (.github/workflows/ci.yml)"
            case .gitlabCI: "GitLab CI (.gitlab-ci.yml)"
            case .bitrise: "Bitrise (bitrise.yml)"
            case .xcodeCloud: "Xcode Cloud (ci_scripts/ci_post_clone.sh)"
            case .none: "None (Skip CI/CD Setup)"
        }
    }
}

public struct CICDConfig: Codable, Equatable {
    public var provider: CICDProvider

    public init(provider: CICDProvider = .githubActions) {
        self.provider = provider
    }
}
