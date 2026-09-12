# Bricks Catalog

This catalog details all **28 built-in Bricks** provided out-of-the-box by **SwiftBlock**. Bricks are categorized into 4 User-First functional layers: **Config**, **Core**, **Feature**, and **Utils**.

---

## 1. App & Configuration Bricks

App & Configuration bricks manage global application state, environment setup, feature toggles, and URL routing parsers.

### Config

Runtime Environment Configuration Manager.

```bash
swiftblock snap config
```

- **Output**: `App/Sources/Core/Config/AppConfig.swift`
- **Features**: Staging/Production environment configuration, API base URL resolution.

```swift
// Code Example: Using AppConfig
let apiURL = AppConfig.apiBaseURL
```

---

### App State

Application State Manager.

```bash
swiftblock snap appstate
```

- **Output**: `App/Sources/Core/AppState/AppStateService.swift`
- **Features**: Centralized reactive app state store using Swift's `@Observable`.

---

### Feature Flag

Dynamic Feature Toggle Engine.

```bash
swiftblock snap featureflag
```

- **Output**: `App/Sources/Core/FeatureFlag/FeatureFlagService.swift`
- **Features**: Dynamic local and remote feature flag evaluation.

---

### Deep Link

URL Scheme & Universal Link Parser.

```bash
swiftblock snap deeplink
```

- **Output**: `App/Sources/Core/DeepLink/DeepLinkService.swift`
- **Features**: Deep link URL route parser and application launch handler.

---

## 2. Core Infrastructure Bricks

Infrastructure bricks provide shared low-level I/O, security, storage, analytics, and system hardware services snapped once into your application core.

### Network

Unified HTTP Transport Engine.

```bash
swiftblock snap network
```

- **Output**: `App/Sources/Core/Network/NetworkService.swift`
- **Features**: `URLSession` wrapper, Swift Concurrency `async/await`, custom request interceptors, automatic JSON decoding.

```swift
// Code Example: Using NetworkService
let network = NetworkService()
let user: UserProfile = try await network.request(Endpoint.getProfile)
```

---

### Secure Storage

Keychain Security Engine.

```bash
swiftblock snap securestorage
```

- **Output**: `App/Sources/Core/SecureStorage/SecureStorageService.swift`
- **Features**: Hardware-backed iOS/macOS Keychain reader/writer for OAuth tokens and sensitive credentials.

```swift
// Code Example: Storing Credentials
let secureStorage = SecureStorageService()
try secureStorage.save(token, forKey: "authToken")
```

---

### Auth

Authentication & Session Manager.

```bash
swiftblock snap auth
```

- **Output**: `App/Sources/Core/Auth/AuthService.swift`
- **Features**: Session state machine, token refresh handling, secure login/logout hooks.

---

### Storage

SwiftData / Local Database Engine.

```bash
swiftblock snap storage
```

- **Output**: `App/Sources/Core/Storage/StorageService.swift`
- **Features**: Type-safe local database abstraction supporting SwiftData or CoreData.

---

### Analytics

Telemetry & Event Tracking Engine.

```bash
swiftblock snap analytics
```

- **Output**: `App/Sources/Core/Analytics/AnalyticsService.swift`
- **Features**: Unified analytics provider interface for tracking user events and telemetry.

---

### Logger

SwiftLog Unified Logging Engine.

```bash
swiftblock snap logger
```

- **Output**: `App/Sources/Core/Logger/LoggerService.swift`
- **Features**: Structured OSLog integration with privacy-redacted log formatting.

---

### Biometrics

FaceID & TouchID Authentication.

```bash
swiftblock snap biometrics
```

- **Output**: `App/Sources/Core/Biometrics/BiometricAuthService.swift`
- **Features**: `LocalAuthentication` wrapper for FaceID/TouchID prompt workflows.

---

### Cache

Memory & Disk Cache Engine.

```bash
swiftblock snap cache
```

- **Output**: `App/Sources/Core/Cache/CacheService.swift`
- **Features**: Two-tier memory and disk cache with TTL expiry policy.

---

### Notification

Push & Local Notification Manager.

```bash
swiftblock snap notification
```

- **Output**: `App/Sources/Core/Notification/NotificationService.swift`
- **Features**: `UNUserNotificationCenter` authorization, local alert scheduling, and APNs token handler.

---

### Permissions

System Privacy Permissions Engine.

```bash
swiftblock snap permissions
```

- **Output**: `App/Sources/Core/Permissions/PermissionsService.swift`
- **Features**: Unified permission request coordinator for Camera, Microphone, Photo Library, and Contacts.

---

## 3. Feature Architecture Bricks

Feature bricks generate architectural layers for specific feature modules (e.g., `Profile`, `Home`, `Checkout`).

### Scene

SwiftUI View + ViewModel.

```bash
swiftblock snap scene Home
```

- **Output**:
  - `App/Sources/Features/Home/HomeView.swift`
  - `App/Sources/Features/Home/HomeViewModel.swift`

```swift
// Code Example: Generated HomeView
struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    
    var body: some View {
        VStack {
            Text("Home Feature")
        }
    }
}
```

---

### Use Case

Domain Logic Unit.

```bash
swiftblock snap usecase AuthenticateUser
```

- **Output**: `App/Sources/Features/AuthenticateUser/AuthenticateUserUseCase.swift`
- **Features**: Encapsulates single-responsibility business logic according to Clean Architecture.

---

### Repository

Data Access Abstraction.

```bash
swiftblock snap repository User
```

- **Output**: `App/Sources/Features/User/UserRepository.swift`
- **Features**: Mediates between remote API services and local database cache.

---

### Service

Remote API Client Service.

```bash
swiftblock snap service Payment
```

- **Output**: `App/Sources/Features/Payment/PaymentService.swift`

---

### Coordinator

Navigation Flow Coordinator.

```bash
swiftblock snap coordinator Main
```

- **Output**: `App/Sources/Features/Main/MainCoordinator.swift`
- **Features**: Decouples navigation routing from SwiftUI Views using NavigationPath.

---

### Component

Reusable SwiftUI UI Component.

```bash
swiftblock snap component PrimaryButton
```

- **Output**: `App/Sources/Features/Components/PrimaryButton.swift`

---

### Entity

Domain Data Model.

```bash
swiftblock snap entity Transaction
```

- **Output**: `App/Sources/Features/Models/TransactionEntity.swift`

---

### Mapper

Model Transformer.

```bash
swiftblock snap mapper User
```

- **Output**: `App/Sources/Features/User/UserMapper.swift`
- **Features**: Transforms DTO models into Domain entities cleanly.

---

## 4. Utilities & Value Types Bricks

Utility bricks provide specialized validation rules, data formatting, system location tracking, and domain value objects.

### Validator

Input Validation Engine.

```bash
swiftblock snap validator Email
```

- **Available Types (7)**: `CreditCard`, `Email`, `Health`, `IBAN`, `Password`, `Phone`, `URL`.

```swift
let isValid = EmailValidator.validate("user@example.com") // true
```

---

### Formatter

Data Formatter Helpers.

```bash
swiftblock snap formatter Currency
```

- **Available Types (7)**: `Byte`, `Currency`, `Date`, `Duration`, `Health`, `Number`, `RelativeDate`.

---

### Connectivity

Network Reachability Monitor.

```bash
swiftblock snap connectivity
```

- **Output**: `App/Sources/Core/Connectivity/ConnectivityService.swift`
- **Features**: Real-time network interface reachability tracking using `NWPathMonitor`.

---

### Location

CoreLocation Engine.

```bash
swiftblock snap location
```

- **Output**: `App/Sources/Core/Location/LocationService.swift`
- **Features**: `CoreLocation` wrapper for GPS positioning and geofencing.

---

### Value Types

Domain Value Objects (37 Types).

```bash
swiftblock snap valuetype Money
```

- **Available Types (37)**: `BatteryLevel`, `BloodPressure`, `Calorie`, `Coordinate`, `Credit`, `DateRange`, `Dimensions`, `Distance`, `Duration`, `EmailAddress`, `ExchangeRate`, `HeartRate`, `HexColor`, `IPAddress`, `Identifier`, `LicensePlate`, `MIMEType`, `MobileCredit`, `MobileData`, `MobileMinutes`, `MobileSMS`, `Money`, `NationalID`, `NonNegative`, `Percentage`, `PhoneNumber`, `Point`, `Quantity`, `Rating`, `SKU`, `SemanticVersion`, `Speed`, `TaxNumber`, `Temperature`, `TimeSlot`, `VirtualAccount`, `Weight`.

```swift
// Code Example: Type-Safe Money Value Type
let price = Money(amount: 49.99, currency: .usd)
print(price.formatted()) // "$49.99"
```

---

## Next Steps

- Learn how to build [Custom Bricks & Box Registries](file:///Users/ardyan/Development/SwiftBlock/Docs/05-Custom-Bricks-and-Boxes.md).
- See how to compose bricks using [Composition Kits](file:///Users/ardyan/Development/SwiftBlock/Docs/06-Composition-Kits.md).
