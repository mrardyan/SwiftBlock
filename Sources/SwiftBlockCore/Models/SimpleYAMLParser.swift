import Foundation

public enum SimpleYAMLParser {
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
                guard let colon = findMappingColon(in: content) else {
                    idx += 1
                    continue
                }

                let key = String(content[..<colon]).trimmingCharacters(in: .whitespaces)
                let valStr = String(content[content.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
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

                let isQuoted = (itemStr.hasPrefix("\"") && itemStr.hasSuffix("\"")) ||
                    (itemStr.hasPrefix("'") && itemStr.hasSuffix("'"))

                if !isQuoted, let colon = findMappingColon(in: itemStr) {
                    // Dict-style list item (possibly with continuation attributes)
                    let key = String(itemStr[..<colon]).trimmingCharacters(in: .whitespaces)
                    let valStr = String(itemStr[itemStr.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
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
                              let contColon = findMappingColon(in: contContent) else { break }
                        let contKey = String(contContent[..<contColon]).trimmingCharacters(in: .whitespaces)
                        let contVal = String(contContent[contContent.index(after: contColon)...]).trimmingCharacters(in: .whitespaces)
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

    /// Finds the colon separating a key and value in a YAML line, ignoring colons inside quotes
    /// and ensuring the colon is followed by a space or is at the end of the line.
    private static func findMappingColon(in str: String) -> String.Index? {
        var inDoubleQuote = false
        var inSingleQuote = false
        var isEscaped = false
        var i = str.startIndex
        while i < str.endIndex {
            let ch = str[i]
            if isEscaped {
                isEscaped = false
                i = str.index(after: i)
                continue
            }
            if ch == "\\", inDoubleQuote || inSingleQuote {
                isEscaped = true
                i = str.index(after: i)
                continue
            }
            if ch == "\"", !inSingleQuote {
                inDoubleQuote.toggle()
            } else if ch == "'", !inDoubleQuote {
                inSingleQuote.toggle()
            } else if ch == ":", !inDoubleQuote, !inSingleQuote {
                let next = str.index(after: i)
                if next == str.endIndex || str[next] == " " {
                    return i
                }
            }
            i = str.index(after: i)
        }
        return nil
    }

    /// Strips `#` comments while preserving them inside single or double quotes,
    /// correctly handling escaped quotes.
    private static func stripComments(_ rawLine: String) -> String {
        var line = ""
        var inDoubleQuote = false
        var inSingleQuote = false
        var isEscaped = false
        for char in rawLine {
            if isEscaped {
                isEscaped = false
                line.append(char)
                continue
            }
            if char == "\\", inDoubleQuote || inSingleQuote {
                isEscaped = true
                line.append(char)
                continue
            }
            if char == "\"", !inSingleQuote {
                inDoubleQuote.toggle()
            } else if char == "'", !inDoubleQuote {
                inSingleQuote.toggle()
            } else if char == "#", !inDoubleQuote, !inSingleQuote {
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
