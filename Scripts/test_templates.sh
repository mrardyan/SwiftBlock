#!/bin/bash
set -e

echo "🧪 Running SwiftBlock Brick Templates Test Suite..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMP_DIR="$(mktemp -d)/SwiftBlockTemplatesTest"

mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
swift package init --type library > /dev/null

cat << 'PACKAGE_EOF' > "$TEMP_DIR/Package.swift"
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftBlockTemplatesTest",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(name: "SwiftBlockTemplatesTest", targets: ["SwiftBlockTemplatesTest"]),
    ],
    targets: [
        .target(name: "SwiftBlockTemplatesTest"),
        .testTarget(name: "SwiftBlockTemplatesTestTests", dependencies: ["SwiftBlockTemplatesTest"]),
    ]
)
PACKAGE_EOF

rm -rf "$TEMP_DIR/Sources/SwiftBlockTemplatesTest/"*
rm -rf "$TEMP_DIR/Tests/SwiftBlockTemplatesTestTests/"*

copy_brick_folder() {
    local src_dir="$1"
    local prefix="$2"

    for file in "$src_dir"/*.swift; do
        if [ -f "$file" ]; then
            filename="$(basename "$file")"
            if [[ "$filename" == *"Tests.swift" ]]; then
                target_name="${prefix}$(echo "$filename" | sed "s/__MODULE_NAME__//")"
                sed -e "s/@testable import __MODULE_NAME__/@testable import SwiftBlockTemplatesTest/g" \
                    -e "s/@testable import __PROJECT_NAME__/@testable import SwiftBlockTemplatesTest/g" \
                    -e "s/__MODULE_NAME__/${prefix}/g" "$file" > "$TEMP_DIR/Tests/SwiftBlockTemplatesTestTests/$target_name"
            else
                target_name="${prefix}$(echo "$filename" | sed "s/__MODULE_NAME__//")"
                sed -e "s/__MODULE_NAME__/${prefix}/g" "$file" > "$TEMP_DIR/Sources/SwiftBlockTemplatesTest/$target_name"
            fi
        fi
    done
}

echo "📦 Collecting singleton brick templates..."

for category_dir in "$ROOT_DIR/Bricks/Singletons"/*; do
    if [ -d "$category_dir" ]; then
        category_name="$(basename "$category_dir")"
        
        has_subbricks=false
        for sub_dir in "$category_dir"/*; do
            if [ -d "$sub_dir" ] && [ -f "$sub_dir/brick.yml" ]; then
                has_subbricks=true
                sub_name="$(basename "$sub_dir")"
                prefix="Test${category_name}${sub_name}"
                copy_brick_folder "$sub_dir" "$prefix"
            fi
        done

        if [ "$has_subbricks" = false ] && [ -f "$category_dir/brick.yml" ]; then
            prefix="Test${category_name}"
            copy_brick_folder "$category_dir" "$prefix"
        fi
    fi
done

echo "🔨 Compiling and executing XCTest suites..."
swift test

echo "✅ All brick templates compiled and passed unit tests successfully!"
rm -rf "$TEMP_DIR"
