import Foundation

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
