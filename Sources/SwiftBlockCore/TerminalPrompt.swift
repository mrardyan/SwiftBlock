import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public enum ANSIColor {
    public static let reset = "\u{001B}[0m"
    public static let bold = "\u{001B}[1m"
    public static let dim = "\u{001B}[90m"
    public static let cyan = "\u{001B}[36m"
    public static let green = "\u{001B}[32m"
    public static let yellow = "\u{001B}[33m"
    public static let red = "\u{001B}[31m"
    
    public static func boldText(_ text: String) -> String { "\(bold)\(text)\(reset)" }
    public static func dimText(_ text: String) -> String { "\(dim)\(text)\(reset)" }
    public static func cyanText(_ text: String) -> String { "\(cyan)\(text)\(reset)" }
    public static func greenText(_ text: String) -> String { "\(green)\(text)\(reset)" }
    public static func yellowText(_ text: String) -> String { "\(yellow)\(text)\(reset)" }
    public static func redText(_ text: String) -> String { "\(red)\(text)\(reset)" }
}

public struct ChoiceOption {
    public let title: String
    public let subtitle: String?

    public init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
}

public class TerminalPrompt {
    
    private static func visibleLength(_ text: String) -> Int {
        let clean = text.replacingOccurrences(
            of: #"\x1B\[[0-9;?]*[a-zA-Z~]"#,
            with: "",
            options: .regularExpression
        )
        return clean.count
    }

    private static func getTerminalColumns() -> Int {
        var ws = winsize()
        if ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &ws) == 0 && ws.ws_col > 0 {
            return Int(ws.ws_col)
        }
        return 80
    }

    private static func physicalLineCount(for text: String, columns: Int) -> Int {
        let len = visibleLength(text)
        if len == 0 { return 1 }
        return max(1, (len + columns - 1) / columns)
    }

    private static func getByteWithTimeout(ms: Int = 30) -> UInt8? {
        var fds = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
        let ret = poll(&fds, 1, Int32(ms))
        if ret <= 0 { return nil }
        var byte: UInt8 = 0
        let n = read(STDIN_FILENO, &byte, 1)
        return n == 1 ? byte : nil
    }

    private static func confirmExit(
        currentRenderedLines: inout Int,
        reRender: () -> Void
    ) -> Bool {
        if currentRenderedLines > 0 {
            print("\r\u{001B}[\(currentRenderedLines)A\u{001B}[J", terminator: "")
            currentRenderedLines = 0
        }
        let exitConfirmed = confirm(title: "Cancel setup and exit?", defaultYes: true)
        if !exitConfirmed {
            reRender()
        }
        return exitConfirmed
    }

    public static func selectChoice(
        title: String,
        options: [ChoiceOption],
        defaultIndex: Int = 0,
        readLineFallback: () -> String? = { Swift.readLine() }
    ) -> Int? {
        guard !options.isEmpty else { return nil }
        
        let isTTY = isatty(STDIN_FILENO) != 0
        if !isTTY {
            return fallbackChoice(title: title, options: options, readLine: readLineFallback)
        }

        var oldTerm = termios()
        if tcgetattr(STDIN_FILENO, &oldTerm) != 0 {
            return fallbackChoice(title: title, options: options, readLine: readLineFallback)
        }

        var rawTerm = oldTerm
        rawTerm.c_lflag &= ~tcflag_t(ICANON | ECHO)
        withUnsafeMutablePointer(to: &rawTerm.c_cc) { ptr in
            let base = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: cc_t.self)
            base[Int(VMIN)] = 1
            base[Int(VTIME)] = 0
        }

        if tcsetattr(STDIN_FILENO, TCSANOW, &rawTerm) != 0 {
            return fallbackChoice(title: title, options: options, readLine: readLineFallback)
        }

        // Hide cursor
        print("\u{001B}[?25l", terminator: "")
        fflush(stdout)

        defer {
            // Restore terminal settings & show cursor
            print("\u{001B}[?25h", terminator: "")
            fflush(stdout)
            tcsetattr(STDIN_FILENO, TCSANOW, &oldTerm)
        }

        var selectedIndex = min(max(0, defaultIndex), options.count - 1)
        var totalRenderedLines = 0

        func renderMenu() {
            let cols = getTerminalColumns()

            if totalRenderedLines > 0 {
                // Clear previous physical lines
                print("\r\u{001B}[\(totalRenderedLines)A\u{001B}[J", terminator: "")
            }

            var linesCount = 0
            
            // Question header
            let header = "│  \(ANSIColor.cyanText("?"))  \(ANSIColor.boldText(title)) \(ANSIColor.dimText("(↑/↓ to navigate, ESC/Ctrl+C to exit)"))"
            print(header)
            linesCount += physicalLineCount(for: header, columns: cols)

            for (idx, option) in options.enumerated() {
                let isSelected = idx == selectedIndex
                let prefix = isSelected ? "│    \(ANSIColor.cyanText("❯")) " : "│      "
                let lineText: String
                
                if isSelected {
                    let titleText = ANSIColor.boldText(ANSIColor.cyanText(option.title))
                    if let subtitle = option.subtitle, !subtitle.isEmpty {
                        lineText = "\(prefix)\(titleText) \(ANSIColor.dimText("(\(subtitle))"))"
                    } else {
                        lineText = "\(prefix)\(titleText)"
                    }
                } else {
                    let titleText = option.title
                    if let subtitle = option.subtitle, !subtitle.isEmpty {
                        lineText = "\(prefix)\(titleText) \(ANSIColor.dimText("(\(subtitle))"))"
                    } else {
                        lineText = "\(prefix)\(titleText)"
                    }
                }
                
                print(lineText)
                linesCount += physicalLineCount(for: lineText, columns: cols)
            }

            fflush(stdout)
            totalRenderedLines = linesCount
        }

        renderMenu()

        func getByte() -> UInt8? {
            var byte: UInt8 = 0
            let n = read(STDIN_FILENO, &byte, 1)
            return n == 1 ? byte : nil
        }

        while true {
            guard let byte = getByte() else { break }

            if byte == 0x0A || byte == 0x0D { // Enter
                if totalRenderedLines > 0 {
                    print("\r\u{001B}[\(totalRenderedLines)A\u{001B}[J", terminator: "")
                }
                let selectedTitle = options[selectedIndex].title
                print("│  \(ANSIColor.greenText("✔"))  \(title) › \(ANSIColor.cyanText(selectedTitle))")
                fflush(stdout)
                return selectedIndex
            } else if byte == 0x03 || byte == 0x04 { // Ctrl+C or Ctrl+D
                if confirmExit(currentRenderedLines: &totalRenderedLines, reRender: { renderMenu() }) {
                    print("│  \(ANSIColor.redText("✖"))  \(title) \(ANSIColor.dimText("(Cancelled)"))")
                    fflush(stdout)
                    return nil
                }
            } else if byte == 0x1B { // Escape sequence (Arrow keys or ESC)
                if let b2 = getByteWithTimeout(ms: 30), (b2 == 0x5B || b2 == 0x4F) {
                    if let b3 = getByteWithTimeout(ms: 30) {
                        switch b3 {
                        case 0x41: // Up Arrow ('A')
                            selectedIndex = (selectedIndex - 1 + options.count) % options.count
                            renderMenu()
                        case 0x42: // Down Arrow ('B')
                            selectedIndex = (selectedIndex + 1) % options.count
                            renderMenu()
                        default:
                            break
                        }
                    }
                } else {
                    // Standalone ESC
                    if confirmExit(currentRenderedLines: &totalRenderedLines, reRender: { renderMenu() }) {
                        print("│  \(ANSIColor.redText("✖"))  \(title) \(ANSIColor.dimText("(Cancelled)"))")
                        fflush(stdout)
                        return nil
                    }
                }
            } else if byte == 0x6B || byte == 0x4B { // 'k' or 'K' (vim up)
                selectedIndex = (selectedIndex - 1 + options.count) % options.count
                renderMenu()
            } else if byte == 0x6A || byte == 0x4A { // 'j' or 'J' (vim down)
                selectedIndex = (selectedIndex + 1) % options.count
                renderMenu()
            }
        }

        return selectedIndex
    }

    public struct MultiChoiceOption {
        public let id: String
        public let title: String
        public let subtitle: String?
        public var isSelected: Bool

        public init(id: String, title: String, subtitle: String? = nil, isSelected: Bool = true) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.isSelected = isSelected
        }
    }

    public static func selectMultiChoice(
        title: String,
        options: [MultiChoiceOption],
        readLineFallback: () -> String? = { Swift.readLine() }
    ) -> [String] {
        guard !options.isEmpty else { return [] }

        let isTTY = isatty(STDIN_FILENO) != 0
        if !isTTY {
            return options.filter { $0.isSelected }.map { $0.id }
        }

        var oldTerm = termios()
        if tcgetattr(STDIN_FILENO, &oldTerm) != 0 {
            return options.filter { $0.isSelected }.map { $0.id }
        }

        var rawTerm = oldTerm
        rawTerm.c_lflag &= ~tcflag_t(ICANON | ECHO)
        withUnsafeMutablePointer(to: &rawTerm.c_cc) { ptr in
            let base = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: cc_t.self)
            base[Int(VMIN)] = 1
            base[Int(VTIME)] = 0
        }

        if tcsetattr(STDIN_FILENO, TCSANOW, &rawTerm) != 0 {
            return options.filter { $0.isSelected }.map { $0.id }
        }

        print("\u{001B}[?25l", terminator: "")
        fflush(stdout)

        defer {
            print("\u{001B}[?25h", terminator: "")
            fflush(stdout)
            tcsetattr(STDIN_FILENO, TCSANOW, &oldTerm)
        }

        var stateOptions = options
        var highlightedIndex = 0
        var totalRenderedLines = 0

        func renderMenu() {
            let cols = getTerminalColumns()

            if totalRenderedLines > 0 {
                print("\r\u{001B}[\(totalRenderedLines)A\u{001B}[J", terminator: "")
            }

            var linesCount = 0

            let header = "│  \(ANSIColor.cyanText("?"))  \(ANSIColor.boldText(title)) \(ANSIColor.dimText("(↑/↓ to move, Space to toggle, 'a' to all, Enter to submit)"))"
            print(header)
            linesCount += physicalLineCount(for: header, columns: cols)

            for (idx, option) in stateOptions.enumerated() {
                let isCursorHere = idx == highlightedIndex
                let checkbox = option.isSelected ? ANSIColor.greenText("[✔]") : ANSIColor.dimText("[ ]")
                let cursorPrefix = isCursorHere ? "│    \(ANSIColor.cyanText("❯")) " : "│      "

                let lineText: String
                let titleText = isCursorHere ? ANSIColor.boldText(ANSIColor.cyanText(option.title)) : option.title
                if let subtitle = option.subtitle, !subtitle.isEmpty {
                    lineText = "\(cursorPrefix)\(checkbox) \(titleText) \(ANSIColor.dimText("(\(subtitle))"))"
                } else {
                    lineText = "\(cursorPrefix)\(checkbox) \(titleText)"
                }

                print(lineText)
                linesCount += physicalLineCount(for: lineText, columns: cols)
            }

            fflush(stdout)
            totalRenderedLines = linesCount
        }

        renderMenu()

        func getByte() -> UInt8? {
            var byte: UInt8 = 0
            let n = read(STDIN_FILENO, &byte, 1)
            return n == 1 ? byte : nil
        }

        while true {
            guard let byte = getByte() else { break }

            if byte == 0x0A || byte == 0x0D { // Enter
                if totalRenderedLines > 0 {
                    print("\r\u{001B}[\(totalRenderedLines)A\u{001B}[J", terminator: "")
                }
                let selectedTitles = stateOptions.filter { $0.isSelected }.map { $0.title }
                let summaryText = selectedTitles.isEmpty ? ANSIColor.dimText("None") : ANSIColor.cyanText(selectedTitles.joined(separator: ", "))
                print("│  \(ANSIColor.greenText("✔"))  \(title) › \(summaryText)")
                fflush(stdout)
                return stateOptions.filter { $0.isSelected }.map { $0.id }
            } else if byte == 0x20 { // Space (toggle item)
                stateOptions[highlightedIndex].isSelected.toggle()
                renderMenu()
            } else if byte == 0x61 || byte == 0x41 { // 'a' or 'A' (toggle all)
                let allSelected = stateOptions.allSatisfy { $0.isSelected }
                for i in 0..<stateOptions.count {
                    stateOptions[i].isSelected = !allSelected
                }
                renderMenu()
            } else if byte == 0x03 || byte == 0x04 { // Ctrl+C or Ctrl+D
                if confirmExit(currentRenderedLines: &totalRenderedLines, reRender: { renderMenu() }) {
                    print("│  \(ANSIColor.redText("✖"))  \(title) \(ANSIColor.dimText("(Cancelled)"))")
                    fflush(stdout)
                    return []
                }
            } else if byte == 0x1B { // Escape sequence (Arrow keys or ESC)
                if let b2 = getByteWithTimeout(ms: 30), (b2 == 0x5B || b2 == 0x4F) {
                    if let b3 = getByteWithTimeout(ms: 30) {
                        switch b3 {
                        case 0x41: // Up Arrow ('A')
                            highlightedIndex = (highlightedIndex - 1 + stateOptions.count) % stateOptions.count
                            renderMenu()
                        case 0x42: // Down Arrow ('B')
                            highlightedIndex = (highlightedIndex + 1) % stateOptions.count
                            renderMenu()
                        default:
                            break
                        }
                    }
                } else {
                    // Standalone ESC
                    if confirmExit(currentRenderedLines: &totalRenderedLines, reRender: { renderMenu() }) {
                        print("│  \(ANSIColor.redText("✖"))  \(title) \(ANSIColor.dimText("(Cancelled)"))")
                        fflush(stdout)
                        return []
                    }
                }
            } else if byte == 0x6B || byte == 0x4B { // 'k' or 'K' (vim up)
                highlightedIndex = (highlightedIndex - 1 + stateOptions.count) % stateOptions.count
                renderMenu()
            } else if byte == 0x6A || byte == 0x4A { // 'j' or 'J' (vim down)
                highlightedIndex = (highlightedIndex + 1) % stateOptions.count
                renderMenu()
            }
        }

        return stateOptions.filter { $0.isSelected }.map { $0.id }
    }

    public static func confirm(
        title: String,
        defaultYes: Bool = true,
        readLineFallback: () -> String? = { Swift.readLine() }
    ) -> Bool {
        let isTTY = isatty(STDIN_FILENO) != 0
        if !isTTY {
            let suffix = defaultYes ? "[Y/n]" : "[y/N]"
            print("│  \(ANSIColor.cyanText("?"))  \(title) \(suffix): ", terminator: "")
            fflush(stdout)
            guard let line = readLineFallback()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !line.isEmpty else {
                return defaultYes
            }
            return line.hasPrefix("y")
        }

        var oldTerm = termios()
        if tcgetattr(STDIN_FILENO, &oldTerm) != 0 {
            let suffix = defaultYes ? "[Y/n]" : "[y/N]"
            print("│  \(ANSIColor.cyanText("?"))  \(title) \(suffix): ", terminator: "")
            fflush(stdout)
            guard let line = readLineFallback()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !line.isEmpty else {
                return defaultYes
            }
            return line.hasPrefix("y")
        }

        var rawTerm = oldTerm
        rawTerm.c_lflag &= ~tcflag_t(ICANON | ECHO)
        withUnsafeMutablePointer(to: &rawTerm.c_cc) { ptr in
            let base = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: cc_t.self)
            base[Int(VMIN)] = 1
            base[Int(VTIME)] = 0
        }

        if tcsetattr(STDIN_FILENO, TCSANOW, &rawTerm) != 0 {
            let suffix = defaultYes ? "[Y/n]" : "[y/N]"
            print("│  \(ANSIColor.cyanText("?"))  \(title) \(suffix): ", terminator: "")
            fflush(stdout)
            guard let line = readLineFallback()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !line.isEmpty else {
                return defaultYes
            }
            return line.hasPrefix("y")
        }

        // Hide cursor
        print("\u{001B}[?25l", terminator: "")
        fflush(stdout)

        defer {
            // Restore terminal settings & show cursor
            print("\u{001B}[?25h", terminator: "")
            fflush(stdout)
            tcsetattr(STDIN_FILENO, TCSANOW, &oldTerm)
        }

        var isYesSelected = defaultYes
        var totalRenderedLines = 0

        func renderPrompt() {
            let cols = getTerminalColumns()

            if totalRenderedLines > 0 {
                print("\r\u{001B}[\(totalRenderedLines)A\u{001B}[J", terminator: "")
            }

            let yesOption = isYesSelected ? ANSIColor.boldText(ANSIColor.cyanText("● Yes")) : ANSIColor.dimText("○ Yes")
            let noOption = !isYesSelected ? ANSIColor.boldText(ANSIColor.cyanText("● No")) : ANSIColor.dimText("○ No")
            
            let promptLine = "│  \(ANSIColor.cyanText("?"))  \(ANSIColor.boldText(title)) › \(yesOption)  \(noOption)  \(ANSIColor.dimText("(←/→ to switch, Enter to submit)"))"
            print(promptLine)
            fflush(stdout)
            totalRenderedLines = physicalLineCount(for: promptLine, columns: cols)
        }

        renderPrompt()

        func getByte() -> UInt8? {
            var byte: UInt8 = 0
            let n = read(STDIN_FILENO, &byte, 1)
            return n == 1 ? byte : nil
        }

        while true {
            guard let byte = getByte() else { break }

            if byte == 0x0A || byte == 0x0D { // Enter
                if totalRenderedLines > 0 {
                    print("\r\u{001B}[\(totalRenderedLines)A\u{001B}[J", terminator: "")
                }
                let choiceText = isYesSelected ? ANSIColor.greenText("Yes") : ANSIColor.redText("No")
                print("│  \(ANSIColor.greenText("✔"))  \(title) › \(choiceText)")
                fflush(stdout)
                return isYesSelected
            } else if byte == 0x79 || byte == 0x59 { // 'y' or 'Y'
                isYesSelected = true
                renderPrompt()
            } else if byte == 0x6E || byte == 0x4E { // 'n' or 'N'
                isYesSelected = false
                renderPrompt()
            } else if byte == 0x1B { // Escape sequence (Arrow keys or ESC)
                if let b2 = getByteWithTimeout(ms: 30), (b2 == 0x5B || b2 == 0x4F) {
                    if let b3 = getByteWithTimeout(ms: 30) {
                        if b3 == 0x44 || b3 == 0x43 || b3 == 0x41 || b3 == 0x42 {
                            isYesSelected.toggle()
                            renderPrompt()
                        }
                    }
                } else {
                    // Standalone ESC in confirm -> defaults to false (don't exit if already confirming, or return false)
                    if totalRenderedLines > 0 {
                        print("\r\u{001B}[\(totalRenderedLines)A\u{001B}[J", terminator: "")
                    }
                    print("│  \(ANSIColor.redText("✖"))  \(title) › \(ANSIColor.dimText("Cancelled"))")
                    fflush(stdout)
                    return false
                }
            } else if byte == 0x03 || byte == 0x04 { // Ctrl+C / Ctrl+D
                if totalRenderedLines > 0 {
                    print("\r\u{001B}[\(totalRenderedLines)A\u{001B}[J", terminator: "")
                }
                print("│  \(ANSIColor.redText("✖"))  \(title) › \(ANSIColor.dimText("Cancelled"))")
                fflush(stdout)
                return false
            }
        }

        return isYesSelected
    }

    public static func promptInput(
        title: String,
        defaultValue: String? = nil,
        readLineFallback: () -> String? = { InteractiveWizard.readLine() }
    ) -> String {
        let defaultHint = (defaultValue != nil && !defaultValue!.isEmpty) ? " \(ANSIColor.dimText("(default: \(defaultValue!))"))" : ""
        print("│  \(ANSIColor.cyanText("?"))  \(ANSIColor.boldText(title))\(defaultHint): ", terminator: "")
        fflush(stdout)

        guard let rawInput = readLineFallback()?.trimmingCharacters(in: .whitespacesAndNewlines), !rawInput.isEmpty else {
            let result = defaultValue ?? ""
            if isatty(STDIN_FILENO) != 0 {
                print("\r\u{001B}[K", terminator: "")
                print("│  \(ANSIColor.greenText("✔"))  \(title) › \(ANSIColor.cyanText(result))")
                fflush(stdout)
            } else {
                print("")
            }
            return result
        }

        if isatty(STDIN_FILENO) != 0 {
            print("\r\u{001B}[K", terminator: "")
            print("│  \(ANSIColor.greenText("✔"))  \(title) › \(ANSIColor.cyanText(rawInput))")
            fflush(stdout)
        } else {
            print("")
        }
        return rawInput
    }

    private static func fallbackChoice(
        title: String,
        options: [ChoiceOption],
        readLine: () -> String?
    ) -> Int {
        print("\n\(title)")
        for (index, option) in options.enumerated() {
            if let sub = option.subtitle, !sub.isEmpty {
                print("    \(index + 1)) \(option.title) (\(sub))")
            } else {
                print("    \(index + 1)) \(option.title)")
            }
        }
        
        while true {
            print("Choice [1-\(options.count)]: ", terminator: "")
            fflush(stdout)
            guard let line = readLine() else {
                return 0
            }
            let input = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if let choice = Int(input), choice >= 1 && choice <= options.count {
                return choice - 1
            }
            print("⚠️ Invalid choice. Please enter a number between 1 and \(options.count).")
        }
    }
}
