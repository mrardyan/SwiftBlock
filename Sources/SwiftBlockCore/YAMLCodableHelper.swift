import Foundation

public struct SimpleYAMLParser {
    public static func parse(_ yamlString: String) -> [String: Any] {
        var result: [String: Any] = [:]
        let lines = yamlString.components(separatedBy: .newlines)
        
        var stack: [(indent: Int, key: String, dict: [String: Any], isList: Bool, list: [Any])] = []
        var currentDict: [String: Any] = [:]
        
        for rawLine in lines {
            // Strip comments
            var line = rawLine
            if let commentIndex = line.firstIndex(of: "#") {
                line = String(line[..<commentIndex])
            }
            
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            let indent = rawLine.prefix(while: { $0 == " " }).count
            
            // Unwind stack if indent decreased
            while let top = stack.last, indent <= top.indent {
                let finished = stack.removeLast()
                if var parent = stack.last?.dict {
                    if finished.isList && !finished.list.isEmpty {
                        parent[finished.key] = finished.list
                    } else {
                        parent[finished.key] = finished.dict
                    }
                    stack[stack.count - 1].dict = parent
                } else {
                    if finished.isList && !finished.list.isEmpty {
                        result[finished.key] = finished.list
                    } else {
                        result[finished.key] = finished.dict
                    }
                }
            }
            
            if trimmed.hasPrefix("- ") {
                let itemStr = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                let isQuoted = (itemStr.hasPrefix("\"") && itemStr.hasSuffix("\"")) || (itemStr.hasPrefix("'") && itemStr.hasSuffix("'"))
                if !isQuoted && itemStr.contains(":") {
                    let parts = itemStr.split(separator: ":", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
                    let key = parts[0]
                    let value = parts.count > 1 ? parseValue(parts[1]) : ""
                    
                    if var top = stack.last, top.isList {
                        var lastItem = (top.list.last as? [String: Any]) ?? [:]
                        lastItem[key] = value
                        if top.list.isEmpty || !(top.list.last is [String: Any]) {
                            stack[stack.count - 1].list.append([key: value])
                        } else {
                            var list = top.list
                            var dict = (list.removeLast() as? [String: Any]) ?? [:]
                            dict[key] = value
                            list.append(dict)
                            stack[stack.count - 1].list = list
                        }
                    }
                } else {
                    let val = parseValue(itemStr)
                    if var top = stack.last, top.isList {
                        stack[stack.count - 1].list.append(val)
                    }
                }
            } else if trimmed.contains(":") {
                let parts = trimmed.split(separator: ":", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
                let key = parts[0]
                let valStr = parts.count > 1 ? parts[1] : ""
                
                if valStr.isEmpty {
                    // Start of dict or list
                    stack.append((indent: indent, key: key, dict: [:], isList: true, list: []))
                } else {
                    let val = parseValue(valStr)
                    if !stack.isEmpty {
                        if stack[stack.count - 1].isList, var lastDict = stack[stack.count - 1].list.last as? [String: Any] {
                            lastDict[key] = val
                            stack[stack.count - 1].list[stack[stack.count - 1].list.count - 1] = lastDict
                        } else {
                            stack[stack.count - 1].dict[key] = val
                        }
                    } else {
                        result[key] = val
                    }
                }
            }
        }
        
        // Final unwind
        while let finished = stack.popLast() {
            if let parent = stack.last {
                var parentDict = parent.dict
                if finished.isList && !finished.list.isEmpty {
                    parentDict[finished.key] = finished.list
                } else {
                    parentDict[finished.key] = finished.dict
                }
                if !stack.isEmpty {
                    stack[stack.count - 1].dict = parentDict
                } else {
                    result[finished.key] = finished.isList && !finished.list.isEmpty ? finished.list : finished.dict
                }
            } else {
                if finished.isList && !finished.list.isEmpty {
                    result[finished.key] = finished.list
                } else {
                    result[finished.key] = finished.dict
                }
            }
        }
        
        return result
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
