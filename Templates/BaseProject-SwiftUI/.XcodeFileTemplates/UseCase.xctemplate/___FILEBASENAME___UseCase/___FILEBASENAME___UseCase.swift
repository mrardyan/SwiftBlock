// © ___YEAR___ __PROJECT_NAME__. All rights reserved.
//
// README:
// This template defines a protocol and a structure for handling specific parameters.
//
// Protocol: ___FILEBASENAMEASIDENTIFIER___
// - This protocol defines a method `execute(with:)` that accepts an instance of `___FILEBASENAMEASIDENTIFIER___Params` and returns a value of the specified type.
//
// Structure: ___FILEBASENAMEASIDENTIFIER___Params
// - This structure includes a single property `message` with a default value of "Hello, World!".
// - Customize this structure to add or modify parameters as needed for your use case.
//
// Instructions:
// 1. Remove any unnecessary code, including `params` and/or `___FILEBASENAMEASIDENTIFIER___Params`, if not required for your specific use case.
// 2. Define and specify the `return model` for the `execute(with:)` method. Ensure the method returns only domain entities, not other models or data types.
// 3. Implement the protocol in a separate file named `Default___FILEBASENAMEASIDENTIFIER___UseCase.swift`.
//
// Note: Please delete this README comment once you have completed the setup and customization of the template.

import Foundation

protocol ___FILEBASENAMEASIDENTIFIER___ {
    func execute(with params: ___FILEBASENAMEASIDENTIFIER___Params) async throws -> <#return model#>
}

struct ___FILEBASENAMEASIDENTIFIER___Params {
    let message = "Hello, World!"
}
