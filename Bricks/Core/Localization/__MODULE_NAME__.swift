import Foundation

/// Localized string and pluralization helpers backed by `Bundle` and `.strings` catalogs.
public enum __MODULE_NAME__ {
    /// Returns the localized string for `key`, falling back to the key itself when absent.
    public static func localized(
        _ key: String,
        bundle: Bundle = .main,
        table: String? = nil,
        arguments: [CVarArg] = []
    ) -> String {
        let format = NSLocalizedString(key, tableName: table, bundle: bundle, comment: "")
        guard !arguments.isEmpty else { return format }
        return String(format: format, locale: Locale.current, arguments: arguments)
    }

    /// Returns a localized string with pluralization rules for the given count.
    public static func pluralized(
        _ key: String,
        count: Int,
        bundle: Bundle = .main,
        table: String? = nil
    ) -> String {
        let format = NSLocalizedString(key, tableName: table, bundle: bundle, comment: "")
        return String(format: format, locale: Locale.current, arguments: [count])
    }

    /// The currently preferred language code (e.g. "en", "id").
    public static var currentLanguageCode: String {
        return Locale.preferredLanguages.first
            ?? Locale.current.language.languageCode?.identifier
            ?? "en"
    }
}