import XCTest
@testable import __MODULE_NAME__

private struct UserRegistrationForm {
    let email: String
    let age: Int
}

final class __MODULE_NAME__ValidatorTests: XCTestCase {
    func testStringInputValidation() {
        let validator = __MODULE_NAME__Validator<String> { input in
            guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return .invalid(reason: "Input cannot be empty.")
            }
            return .valid
        }

        XCTAssertTrue(validator.validate("valid_string").isValid)
        XCTAssertFalse(validator.validate("").isValid)
    }

    func testNumericInputValidation() {
        let validator = __MODULE_NAME__Validator<Int> { age in
            guard age >= 18 else {
                return .invalid(reason: "Must be at least 18 years old.")
            }
            return .valid
        }

        XCTAssertTrue(validator.validate(21).isValid)
        XCTAssertEqual(validator.validate(15), .invalid(reason: "Must be at least 18 years old."))
    }

    func testCustomModelInputValidation() {
        let validator = __MODULE_NAME__Validator<UserRegistrationForm> { form in
            guard !form.email.isEmpty else {
                return .invalid(reason: "Email is required.")
            }
            guard form.age >= 17 else {
                return .invalid(reason: "Underage.")
            }
            return .valid
        }

        let validForm = UserRegistrationForm(email: "user@example.com", age: 20)
        let invalidForm = UserRegistrationForm(email: "", age: 20)

        XCTAssertTrue(validator.validate(validForm).isValid)
        XCTAssertEqual(validator.validate(invalidForm), .invalid(reason: "Email is required."))
    }
}
