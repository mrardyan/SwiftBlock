import Foundation
import SwiftUI

/// ViewModel managing form field state, validation, and submission for `__MODULE_NAME__`.
@MainActor
public final class __MODULE_NAME__FormViewModel: ObservableObject {
    @Published public var fields: [String: String] = [:]
    @Published public private(set) var errors: [String: String] = [:]
    @Published public private(set) var isSubmitting = false
    @Published public private(set) var didSubmit = false

    public let fieldNames: [String]
    private let onSubmit: ([String: String]) async -> Bool

    public init(
        fieldNames: [String] = ["name", "email"],
        onSubmit: @escaping ([String: String]) async -> Bool = { _ in true }
    ) {
        self.fieldNames = fieldNames
        self.onSubmit = onSubmit
    }

    public func bindingValue(for field: String) -> String {
        return fields[field] ?? ""
    }

    public func update(_ field: String, value: String) {
        fields[field] = value
        errors[field] = nil
    }

    public var isValid: Bool {
        return fieldNames.allSatisfy { !(fields[$0] ?? "").trimmingCharacters(in: .whitespaces).isEmpty }
    }

    @discardableResult
    public func validate() -> Bool {
        var newErrors: [String: String] = [:]
        for field in fieldNames where (fields[field] ?? "").trimmingCharacters(in: .whitespaces).isEmpty {
            newErrors[field] = "\(field.capitalized) is required."
        }
        errors = newErrors
        return newErrors.isEmpty
    }

    public func submit() async {
        guard validate() else { return }
        isSubmitting = true
        let success = await onSubmit(fields)
        isSubmitting = false
        didSubmit = success
    }
}