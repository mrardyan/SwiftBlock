#!/usr/bin/env python3
"""Convert Swift Testing test files to XCTest.

Handles common patterns:
- import Testing -> import XCTest
- struct XTests { -> final class XTests: XCTestCase {
- @Test func name(...) -> func testName(...)
- #expect(a == b) -> XCTAssertEqual(a, b)
- #expect(a != b) -> XCTAssertNotEqual(a, b)
- #expect(!x) -> XCTAssertFalse(x)
- #expect(throws: Never.self) { -> XCTAssertNoThrow {
- #expect(throws: X.self) { -> XCTAssertThrowsError {
- Issue.record(...) -> XCTFail(...)
- other #expect(x) -> XCTAssertTrue(x)
"""
import re
import sys
from pathlib import Path


def convert(content: str) -> str:
    # imports
    content = re.sub(r"^import Testing\n", "import XCTest\n", content, flags=re.M)

    # struct -> final class : XCTestCase
    content = re.sub(
        r"^(struct\s+(\w+Tests))\s*\{",
        r"final class \2: XCTestCase {",
        content,
        flags=re.M,
    )

    # @Test func name() -> func testName()
    def rename_test(m):
        indent, name = m.group(1), m.group(2)
        test_name = name if name.startswith("test") else "test" + name[0].upper() + name[1:]
        return f"{indent}func {test_name}()"

    content = re.sub(
        r"^(\s*)@Test\s+func\s+(\w+)\(\)",
        rename_test,
        content,
        flags=re.M,
    )

    # Issue.record(...) -> XCTFail(...)
    content = re.sub(r"Issue\.record\(", "XCTFail(", content)

    # #expect(throws: Never.self) { ... }  ->  XCTAssertNoThrow { ... }
    content = re.sub(
        r"#expect\(throws:\s*Never\.self\)\s*\{",
        "XCTAssertNoThrow {",
        content,
    )

    # #expect(throws: X.self) { ... }  ->  XCTAssertThrowsError { ... }
    content = re.sub(
        r"#expect\(throws:\s*([A-Za-z0-9_.]+)\.self\)\s*\{",
        r"XCTAssertThrowsError {",
        content,
    )

    # #expect(throws: X.y) { ... }  ->  XCTAssertThrowsError { ... }
    content = re.sub(
        r"#expect\(throws:\s*([A-Za-z0-9_.]+(?:\([^)]*\))?)\)\s*\{",
        r"XCTAssertThrowsError {",
        content,
    )

    # Balance helper: replace simple #expect(...) expressions.
    # We walk char-by-char to respect nested parens.
    result = []
    i = 0
    n = len(content)
    while i < n:
        start = content.find("#expect(", i)
        if start == -1:
            result.append(content[i:])
            break
        result.append(content[i:start])
        # find matching close paren
        depth = 0
        j = start + len("#expect(")
        while j < n:
            if content[j] == "(":
                depth += 1
            elif content[j] == ")":
                if depth == 0:
                    break
                depth -= 1
            j += 1
        if j >= n:
            result.append(content[start:])
            break
        expr = content[start + len("#expect("):j]
        rest = content[j + 1:]

        # If this #expect was already converted (throws block), skip.
        # We detect by checking if the char right after is a '{' and expr
        # starts with 'throws' — those were handled above.
        if expr.strip().startswith("throws"):
            result.append("#expect(" + expr + ")")
            i = j + 1
            continue

        stripped = expr.strip()

        # !x -> XCTAssertFalse
        m = re.fullmatch(r"!\((.+)\)", stripped)
        if not m:
            m = re.fullmatch(r"!(.+)", stripped)
        if m and not re.fullmatch(r"!=\s*.+", stripped):
            inner = m.group(1).strip()
            result.append(f"XCTAssertFalse({inner})")
            i = j + 1
            continue

        # != nil -> XCTAssertNotNil
        m = re.fullmatch(r"(.+?)\s*!=\s*nil", stripped)
        if m:
            result.append(f"XCTAssertNotNil({m.group(1).strip()})")
            i = j + 1
            continue

        # == nil -> XCTAssertNil
        m = re.fullmatch(r"(.+?)\s*==\s*nil", stripped)
        if m:
            result.append(f"XCTAssertNil({m.group(1).strip()})")
            i = j + 1
            continue

        # a != b -> XCTAssertNotEqual
        m = re.fullmatch(r"(.+?)\s*!=\s*(.+)", stripped)
        if m:
            result.append(f"XCTAssertNotEqual({m.group(1).strip()}, {m.group(2).strip()})")
            i = j + 1
            continue

        # a == b -> XCTAssertEqual
        m = re.fullmatch(r"(.+?)\s*==\s*(.+)", stripped)
        if m:
            result.append(f"XCTAssertEqual({m.group(1).strip()}, {m.group(2).strip()})")
            i = j + 1
            continue

        # a < b, a > b, a <= b, a >= b
        m = re.fullmatch(r"(.+?)\s*(<=|>=|<|>)\s*(.+)", stripped)
        if m:
            fn = {"<": "XCTAssertLessThan", ">": "XCTAssertGreaterThan",
                  "<=": "XCTAssertLessThanOrEqual", ">=": "XCTAssertGreaterThanOrEqual"}[m.group(2)]
            result.append(f"{fn}({m.group(1).strip()}, {m.group(3).strip()})")
            i = j + 1
            continue

        # truthy bool -> XCTAssertTrue
        result.append(f"XCTAssertTrue({stripped})")
        i = j + 1

    return "".join(result)


def main() -> None:
    if len(sys.argv) < 2:
        print("usage: convert_swift_testing.py <file> [file ...]")
        sys.exit(1)
    for path_str in sys.argv[1:]:
        p = Path(path_str)
        content = p.read_text(encoding="utf-8")
        converted = convert(content)
        p.write_text(converted, encoding="utf-8")
        print(f"converted {p}")


if __name__ == "__main__":
    main()