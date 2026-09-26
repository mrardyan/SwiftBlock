import Foundation

public struct SimpleYAMLParser {
    public static func parse(_ yamlString: String) -> [String: Any] {
        let lines = yamlString.components(separatedBy: .newlines)
            .map(stripComments)
            .map { (indent: $0.prefix(while: { $0 == " " }).count, content: $0.trimmingCharacters(in: .whitespaces)) }
            .filter { !$0.content.isEmpty }

        var idx = 0

        func parseDict(at indent: Int) -> [String: Any] {
            var dict: [String: Any] = [:]
            while idx < lines.count {
                let (lineIndent, content) = lines[idx]
                if lineIndent < indent { break }
                guard let colon = content.range(of: ":") else { idx += 1; continue }

                let key = String(content[..<colon.lowerBound]).trimmingCharacters(in: .whitespaces)
                let valStr = String(content[colon.upperBound...]).trimmingCharacters(in: .whitespaces)
                idx += 1

                if valStr.isEmpty {
                    if idx < lines.count, lines[idx].indent > lineIndent {
                        let nextContent = lines[idx].content
                        if nextContent.hasPrefix("- ") {
                            dict[key] = parseList(at: lines[idx].indent)
                        } else {
                            dict[key] = parseDict(at: lines[idx].indent)
                        }
                    } else {
                        dict[key] = ""
                    }
                } else {
                    dict[key] = parseValue(valStr)
                }
            }
            return dict
        }

        func parseList(at indent: Int) -> [Any] {
            var list: [Any] = []
            while idx < lines.count {
                let (lineIndent, content) = lines[idx]
                if lineIndent < indent { break }
                guard content.hasPrefix("- ") else { break }
                let itemStr = String(content.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                let itemIndent = lineIndent

                if let colon = itemStr.range(of: ":") {
                    // Dict-style list item (possibly with continuation attributes)
                    let key = String(itemStr[..<colon.lowerBound]).trimmingCharacters(in: .whitespaces)
                    let valStr = String(itemStr[colon.upperBound...]).trimmingCharacters(in: .whitespaces)
                    var item: [String: Any] = [:]
                    idx += 1

                    if valStr.isEmpty {
                        if idx < lines.count, lines[idx].indent > itemIndent {
                            let nextContent = lines[idx].content
                            if nextContent.hasPrefix("- ") {
                                item[key] = parseList(at: lines[idx].indent)
                            } else {
                                item[key] = parseDict(at: lines[idx].indent)
                            }
                        } else {
                            item[key] = ""
                        }
                    } else {
                        item[key] = parseValue(valStr)
                    }

                    // Parse continuation attributes belonging to this list item
                    while idx < lines.count, lines[idx].indent > itemIndent {
                        let (contIndent, contContent) = lines[idx]
                        guard contContent.hasPrefix("- ") == false,
                              let contColon = contContent.range(of: ":") else { break }
                        let contKey = String(contContent[..<contColon.lowerBound]).trimmingCharacters(in: .whitespaces)
                        let contVal = String(contContent[contColon.upperBound...]).trimmingCharacters(in: .whitespaces)
                        idx += 1

                        if contVal.isEmpty {
                            if idx < lines.count, lines[idx].indent > contIndent {
                                let nextContent = lines[idx].content
                                if nextContent.hasPrefix("- ") {
                                    item[contKey] = parseList(at: lines[idx].indent)
                                } else {
                                    item[contKey] = parseDict(at: lines[idx].indent)
                                }
                            } else {
                                item[contKey] = ""
                            }
                        } else {
                            item[contKey] = parseValue(contVal)
                        }
                    }

                    list.append(item)
                } else {
                    // Scalar list item
                    idx += 1
                    list.append(parseValue(itemStr))
                }
            }
            return list
        }

        return parseDict(at: 0)
    }

    /// Strips `#` comments while preserving them inside single or double quotes.
    private static func stripComments(_ rawLine: String) -> String {
        var line = ""
        var inDoubleQuote = false
        var inSingleQuote = false
        for char in rawLine {
            if char == "\"" && !inSingleQuote {
                inDoubleQuote.toggle()
            } else if char == "'" && !inDoubleQuote {
                inSingleQuote.toggle()
            } else if char == "#" && !inDoubleQuote && !inSingleQuote {
                break
            }
            line.append(char)
        }
        return line
    }

    private static func parseValue(_ str: String) -> Any {
        var clean = str.trimmingCharacters(in: .whitespaces)
        if (clean.hasPrefix("\"") && clean.hasSuffix("\"")) || (clean.hasPrefix("'") && clean.hasSuffix("'")) {
            clean = String(clean.dropFirst().dropLast())
            return clean
        }
        if clean.lowercased() == "true" { return true }
        if clean.lowercased() == "false" { return false }
        if let intVal = Int(clean) { return intVal }
        if let doubleVal = Double(clean) { return doubleVal }
        return clean
    }
}