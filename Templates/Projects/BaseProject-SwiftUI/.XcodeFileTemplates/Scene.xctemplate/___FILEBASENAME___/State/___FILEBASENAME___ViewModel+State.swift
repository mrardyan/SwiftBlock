// © ___YEAR___ __PROJECT_NAME__. All rights reserved.
//
// README:
// This extension adds `State` and `Action` types to the `___VARIABLE_productName___ViewModel` class.
//
// Components:
// - `State`: A struct that holds the view model's state. The `State` struct is used to represent the current state of the view, such as data or UI-related values. In this template, it includes a default property `title` with a value of "Hello, World!". You can modify or add properties as needed.
// - `Action`: An enum that defines all possible user actions or events that can trigger changes to the state in the `___VARIABLE_productName___ViewModel`. Each case in this enum represents a different action.
//
// Instructions:
// 1. Add additional properties to the `State` struct to represent other parts of your view's data.
// 2. Populate the `Action` enum with cases that represent the different actions or events that the view model needs to handle.
// 3. Use these structures and enum in conjunction with the `send(_ action: Action)` method within your view model to update the `State` in response to user actions.
//
// Note: After implementing your custom logic, remove this README comment.

import SwiftUI

extension ___VARIABLE_productName___ViewModel {
    struct State {
        var phase: ViewPhase = .initial
        var title: String = "Hello, World!"
    }

    enum Action {
        // Define actions here, such as user interactions or data fetch events
    }

    enum ViewPhase {
        case initial
        case loading
        case loaded
        case error(Error)
    }
}
