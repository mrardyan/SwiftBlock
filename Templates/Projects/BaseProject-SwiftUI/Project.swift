import ProjectDescription

let project = Project(
    name: "__PROJECT_NAME__",
    targets: [
        .target(
            name: "__PROJECT_NAME__",
            destinations: .iOS,
            product: .app,
            bundleId: "__BUNDLE_PREFIX__.__PROJECT_NAME__",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["App/Sources/**"],
            resources: ["App/Resources/**"],
            scripts: [
                .post(
                    script: """
if [[ "$(uname -m)" == arm64 ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

if which swiftlint > /dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
""",
                    name: "Run SwiftLint",
                    basedOnDependencyAnalysis: false
                )
            ],
            dependencies: []
        ),
        .target(
            name: "__PROJECT_NAME__Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "__BUNDLE_PREFIX__.__PROJECT_NAME__Tests",
            infoPlist: .default,
            sources: ["App/Tests/**"],
            resources: [],
            dependencies: [.target(name: "__PROJECT_NAME__")]
        ),
    ]
)
