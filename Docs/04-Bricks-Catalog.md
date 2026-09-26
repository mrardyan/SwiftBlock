# Bricks Catalog

This catalog details all **29 built-in Bricks** provided out-of-the-box by **SwiftBlock**. Bricks are categorized into 4 User-First functional layers: **Config**, **Core**, **Feature**, and **Utils**. Platform compatibility is declared using `baseplates` in `brick.yml` (e.g. `swiftui`, `vapor`, or shared).

---

## 1. App & Configuration Bricks

App & Configuration bricks manage global application state, environment setup, feature toggles, and URL routing parsers.

### Config

Runtime Environment Configuration Manager.

```bash
swiftblock snap config --flavor source=xcconfig
```

- **Output**: `App/Sources/Core/Config/AppConfig.swift`
- **Flavors**:
  - `source`: `xcconfig` (Default), `plist`, `in-memory`
- **Optional Dependencies**: `logger`
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
swiftblock snap featureflag --flavor provider=in-memory
```

- **Output**: `App/Sources/Core/FeatureFlag/FeatureFlagService.swift`
- **Flavors**:
  - `provider`: `in-memory` (Default), `remote-config`, `custom`
- **Mandatory Dependencies**: `keyvaluestoring`
- **Optional Dependencies**: `network`, `logger`
- **Features**: Dynamic local and remote feature flag evaluation.

---

### Deep Link

URL Scheme & Universal Link Parser.

```bash
swiftblock snap deeplink
```

- **Output**: `App/Sources/Core/DeepLink/DeepLinkService.swift`
- **Optional Dependencies**: `logger`
- **Features**: Deep link URL route parser and application launch handler.

---

## 2. Infrastructure & Service Bricks

Infrastructure bricks provide shared low-level I/O, security, storage, analytics, and system hardware services snapped once into your application core.

### Network

Unified HTTP Transport Engine.

```bash
swiftblock snap network --flavor client=urlsession --with-optional circuitbreaker,exponentialbackoff
```

- **Output**: `App/Sources/Core/Network/NetworkService.swift`
- **Flavors**:
  - `client`: `urlsession` (Default), `mock`
- **Optional Dependencies**: `logger`, `connectivity`, `circuitbreaker`, `exponentialbackoff`
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
- **Mandatory Dependencies**: `keyvaluestoring`
- **Optional Dependencies**: `biometrics`, `logger`
- **Features**: Hardware-backed iOS/macOS Keychain reader/writer for OAuth tokens and sensitive credentials.

```swift
// Code Example: Storing Credentials
let secureStorage = SecureStorageService()
try secureStorage.save(token, forKey: "authToken")
```

---

### Auth (SwiftUI / Apple Platforms)

iOS / macOS Keychain Authentication & Session Manager.

```bash
swiftblock snap auth --flavor sessionStore=keychain
```

- **Output**: `App/Sources/Core/Auth/AuthService.swift`
- **Platform**: `swiftui`
- **Flavors**:
  - `sessionStore`: `keychain` (Default), `secure-enclave`
- **Mandatory Dependencies**: `keychain`
- **Optional Dependencies**: `biometrics`, `network`, `logger`
- **Conflicts With**: `vaporauth`
- **Features**: Keychain token storage, session state machine, token refresh handling, secure login/logout hooks.

---

### VaporAuth (Vapor Backend API)

JWT & Session Authentication Manager for Vapor backend API services.

```bash
swiftblock snap vaporauth
```

- **Output**: `Sources/App/Core/Auth/UserAuth.swift`
- **Platform**: `vapor`
- **Optional Dependencies**: `logger`
- **Conflicts With**: `auth`
- **Features**: Pure Swift JWT payload claim generator, bearer token validator, in-memory session revocation manager without Keychain dependency.

```swift
// Code Example: Using VaporAuth
let auth = UserAuth.shared
let token = auth.generateToken(for: "user_123")
if let payload = auth.validateToken(token) {
    print("Authenticated user: \(payload.subject)")
}
```

---

### Storage

SwiftData / Local Database Engine.

```bash
swiftblock snap storage --flavor driver=swiftdata
```

- **Output**: `App/Sources/Core/Storage/StorageService.swift`
- **Flavors**:
  - `driver`: `swiftdata` (Default), `coredata`, `in-memory`
- **Mandatory Dependencies**: `keyvaluestoring`
- **Optional Dependencies**: `logger`
- **Features**: Type-safe local database abstraction supporting SwiftData or CoreData.

---

### Analytics

Telemetry & Event Tracking Engine.

```bash
swiftblock snap analytics --flavor provider=oslog-console
```

- **Output**: `App/Sources/Core/Analytics/AnalyticsService.swift`
- **Flavors**:
  - `provider`: `oslog-console` (Default), `multi-provider`
- **Mandatory Dependencies**: `logging`
- **Optional Dependencies**: `queue`, `storage`
- **Features**: Unified analytics provider interface for tracking user events and telemetry.

---

### Logger

SwiftLog Unified Logging Engine.

```bash
swiftblock snap logger --flavor backend=oslog
```

- **Output**: `App/Sources/Core/Logger/LoggerService.swift`
- **Flavors**:
  - `backend`: `oslog` (Default), `console`
- **Mandatory Dependencies**: `logging`
- **Features**: Structured OSLog integration with privacy-redacted log formatting.

---

### Biometrics

FaceID & TouchID Authentication.

```bash
swiftblock snap biometrics
```

- **Output**: `App/Sources/Core/Biometrics/BiometricAuthService.swift`
- **Optional Dependencies**: `logger`
- **Features**: `LocalAuthentication` wrapper for FaceID/TouchID prompt workflows.

---

### Cache

Memory & Disk Cache Engine.

```bash
swiftblock snap cache --flavor tier=two-tier
```

- **Output**: `App/Sources/Core/Cache/CacheService.swift`
- **Flavors**:
  - `tier`: `two-tier` (Default), `memory-only`, `disk-only`
- **Mandatory Dependencies**: `keyvaluestoring`
- **Optional Dependencies**: `lrucache`, `logger`
- **Features**: Two-tier memory and disk cache with TTL expiry policy.

---

### ImageLoader

Async Image Downloader and Caching Engine.

```bash
swiftblock snap imageloader --flavor cachingPolicy=two-tier
```

- **Output**: `App/Sources/Core/ImageLoader/ImageLoaderService.swift`
- **Flavors**:
  - `cachingPolicy`: `two-tier` (Default), `memory-only`, `disabled`
- **Mandatory Dependencies**: `network`, `cache`
- **Optional Dependencies**: `lrucache`, `logger`
- **Features**: Memory/disk cached async image loading with cache-busting and placeholder fallbacks.

---

### Notification

Push & Local Notification Manager.

```bash
swiftblock snap notification --flavor scope=local-and-remote
```

- **Output**: `App/Sources/Core/Notification/NotificationService.swift`
- **Flavors**:
  - `scope`: `local-and-remote` (Default), `local-only`
- **Mandatory Dependencies**: `permissions`
- **Optional Dependencies**: `logger`, `deeplink`
- **Features**: `UNUserNotificationCenter` authorization, local alert scheduling, and APNs token handler.

---

### Permissions

System Privacy Permissions Engine.

```bash
swiftblock snap permissions
```

- **Output**: `App/Sources/Core/Permissions/PermissionsService.swift`
- **Optional Dependencies**: `logger`
- **Features**: Unified permission request coordinator for Camera, Microphone, Photo Library, and Contacts.

---

## 3. Feature Architecture Bricks

Feature bricks generate architectural layers for specific feature modules (e.g., `Profile`, `Home`, `Checkout`).

### Scene

SwiftUI View + ViewModel.

```bash
swiftblock snap scene Home --flavor stateStyle=observable
```

- **Output**:
  - `App/Sources/Features/Home/HomeView.swift`
  - `App/Sources/Features/Home/HomeViewModel.swift`
- **Flavors**:
  - `stateStyle`: `observable` (Default, Swift 5.9+ `@Observable`), `combine` (`ObservableObject` & `@Published`)
- **Optional Dependencies**: `coordinator`, `usecase`, `haptics`

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
swiftblock snap usecase AuthenticateUser --with-optional exponentialbackoff
```

- **Output**: `App/Sources/Features/AuthenticateUser/AuthenticateUserUseCase.swift`
- **Mandatory Dependencies**: `asyncusecase`
- **Optional Dependencies**: `exponentialbackoff`, `logger`
- **Features**: Encapsulates single-responsibility business logic according to Clean Architecture.

---

### Repository

Data Access Abstraction.

```bash
swiftblock snap repository User --flavor strategy=offline-first
```

- **Output**: `App/Sources/Features/User/UserRepository.swift`
- **Flavors**:
  - `strategy`: `remote-only` (Default), `offline-first`, `local-only`
- **Mandatory Dependencies**: `transforming`
- **Optional Dependencies**: `network`, `storage`, `logger`
- **Features**: Mediates between remote API services and local database cache with conditional code generation.

---

### Service

Remote API Client Service.

```bash
swiftblock snap service Payment --flavor transport=urlsession
```

- **Output**: `App/Sources/Features/Payment/PaymentService.swift`
- **Flavors**:
  - `transport`: `urlsession` (Default), `mock`
- **Mandatory Dependencies**: `network`
- **Optional Dependencies**: `circuitbreaker`, `exponentialbackoff`, `logger`

---

### Coordinator

Navigation Flow Coordinator.

```bash
swiftblock snap coordinator Main --flavor navigationType=navigation-stack
```

- **Output**: `App/Sources/Features/Main/MainCoordinator.swift`
- **Flavors**:
  - `navigationType`: `navigation-stack` (Default), `sheet-modal`
- **Optional Dependencies**: `deeplink`, `analytics`
- **Features**: Decouples navigation routing from SwiftUI Views using NavigationPath.

---

### Form

Reactive Input Form with Validation & Feedback.

```bash
swiftblock snap form Registration --flavor validationTrigger=on-change
```

- **Output**: `App/Sources/Features/Registration/RegistrationFormView.swift`
- **Flavors**:
  - `validationTrigger`: `on-change` (Default), `on-submit`
- **Mandatory Dependencies**: `validating`
- **Optional Dependencies**: `debounce`, `haptics`

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
swiftblock snap mapper User --flavor direction=bidirectional
```

- **Output**: `App/Sources/Features/User/UserMapper.swift`
- **Flavors**:
  - `direction`: `bidirectional` (Default), `domain-only`
- **Mandatory Dependencies**: `transforming`
- **Features**: Transforms DTO models into Domain entities cleanly.

---

## 4. Utilities & Value Types Bricks

Utility bricks provide specialized validation rules, data formatting, system location tracking, and domain value objects.

### Validator

Input Validation Engine.

```bash
swiftblock snap validator Email
```

- **Mandatory Dependencies**: `validating`
- **Protocol Conformance**: Conforms to `Validating` protocol with `.validate(_:)` method and `.and()`, `.or()`, `.not()` combinators.
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

- **Mandatory Dependencies**: `valueformatting`
- **Protocol Conformance**: Conforms to `ValueFormatting` protocol with `.format(_:)` method and `.optional()` fallback chains.
- **Available Types (7)**: `Byte`, `Currency`, `Date`, `Duration`, `Health`, `Number`, `RelativeDate`.

---

### Connectivity

Network Reachability Monitor.

```bash
swiftblock snap connectivity
```

- **Output**: `App/Sources/Core/Connectivity/ConnectivityService.swift`
- **Optional Dependencies**: `logger`
- **Features**: Real-time network interface reachability tracking using `NWPathMonitor`.

---

### Location

CoreLocation Engine.

```bash
swiftblock snap location --flavor precision=best
```

- **Output**: `App/Sources/Core/Location/LocationService.swift`
- **Flavors**:
  - `precision`: `best` (Default), `hundred-meters`, `kilometer`
- **Mandatory Dependencies**: `permissions`
- **Optional Dependencies**: `geofence`, `geodistance`, `geohash`, `logger`
- **Features**: `CoreLocation` wrapper for GPS positioning and geofencing.

---

### Value Types

Domain Value Objects (37 Types).

```bash
swiftblock snap valuetype Money
```

- **Mandatory Dependencies**: `domainvaluetype`
- **Protocol Conformance**: Conforms to `DomainValueType` protocol with immutable value semantics and type safety.
- **Available Types (37)**: `BatteryLevel`, `BloodPressure`, `Calorie`, `Coordinate`, `Credit`, `DateRange`, `Dimensions`, `Distance`, `Duration`, `EmailAddress`, `ExchangeRate`, `HeartRate`, `HexColor`, `IPAddress`, `Identifier`, `LicensePlate`, `MIMEType`, `MobileCredit`, `MobileData`, `MobileMinutes`, `MobileSMS`, `Money`, `NationalID`, `NonNegative`, `Percentage`, `PhoneNumber`, `Point`, `Quantity`, `Rating`, `SKU`, `SemanticVersion`, `Speed`, `TaxNumber`, `Temperature`, `TimeSlot`, `VirtualAccount`, `Weight`.

```swift
// Code Example: Type-Safe Money Value Type
let price = Money(amount: 49.99, currency: .usd)
print(price.formatted()) // "$49.99"
```

---

### Algorithm

Production-Ready Algorithms & Data Structures (18 Algorithms).

```bash
swiftblock snap debounce
swiftblock snap lrucache
swiftblock snap geodistance
swiftblock snap geohash
```

- **Available Algorithms (18)**:
  - **`Debounce`**: Thread-safe task debouncing using async cancellation for search inputs and UI updates.
  - **`Throttle`**: Execution rate limiting with leading & trailing edge options.
  - **`TokenBucket`**: Continuous-replenishing token bucket rate limiter with burst support.
  - **`ExponentialBackoff`**: Exponential retry backoff calculator with Full Jitter and Equal Jitter.
  - **`CircuitBreaker`**: 3-state (`Closed`, `Open`, `HalfOpen`) circuit breaker protecting failing services.
  - **`Levenshtein`**: $O(\min(M, N))$ space-efficient edit distance and text similarity ratio calculator.
  - **`FuzzySearch`**: Ranked subsequence and word-boundary scoring for fast in-app search.
  - **`LRUCache`**: Thread-safe $O(1)$ Least Recently Used in-memory cache using doubly linked list & map.
  - **`PriorityQueue`**: Binary heap min-heap and max-heap priority queue with $O(\log n)$ ops.
  - **`BloomFilter`**: Space-efficient probabilistic set membership filter with 0 false negatives.
  - **`Luhn`**: Modulo 10 checksum algorithm for card, IMEI, and national identifier validation.
  - **`ConsistentHash`**: Consistent hash ring with virtual nodes for distributed sharding and caching.
  - **`BinarySearch`**: Safe binary search, lower bound, and upper bound extensions for sorted collections.
  - **`GeoDistance`**: Haversine distance, initial/final bearing, compass heading, and destination point calculations.
  - **`Geohash`**: Base32 hierarchical spatial index encoding, bounding box decoding, and 8-neighbor proximity lookups.
  - **`PolylineDecoder`**: Google / Mapbox Encoded Polyline algorithm for decoding and encoding compressed GPS routes.
  - **`Geofence`**: Ray-Casting point-in-polygon and circular radius geofence boundary validator.
  - **`DouglasPeucker`**: Ramer-Douglas-Peucker polyline decimation and simplification algorithm for GPS tracks.

```swift
// Code Example: Using GeoDistance and Geofence
let distance = GeoDistance.distance(from: origin, to: destination)
let isInside = Geofence.isPointInPolygon(userLocation, vertices: deliveryZoneVertices)
```

---

### Data Structures

Essential High-Performance Data Structures (8 Types).

```bash
swiftblock snap deque
swiftblock snap trie
swiftblock snap circularbuffer
```

- **Available Data Structures (8)**:
  - **`Deque`**: Double-ended queue with $O(1)$ push and pop operations at both ends.
  - **`Trie`**: Prefix tree for $O(k)$ word search, prefix lookups, and fast autocompletion.
  - **`CircularBuffer`**: Fixed-capacity circular ring buffer that automatically overwrites oldest items.
  - **`OrderedDictionary`**: Dictionary maintaining strict insertion order with $O(1)$ key lookups.
  - **`OrderedSet`**: Unique element set collection that preserves insertion sequence order.
  - **`Stack`**: Classic Last-In-First-Out (LIFO) stack data structure.
  - **`Queue`**: First-In-First-Out (FIFO) queue with amortized $O(1)$ enqueue and dequeue.
  - **`UnionFind`**: Disjoint-set data structure with Path Compression and Union-by-Rank.

```swift
// Code Example: Using Deque and Trie
var deque: Deque<Int> = [10, 20]
deque.prepend(5)
let first = deque.popFirst() // 5

let trie = Trie(words: ["apple", "application", "banana"])
let suggestions = trie.words(matchingPrefix: "app") // ["apple", "application"]
```

---

## 5. Universal Protocol Bricks

Protocol bricks define universal abstractions, decorators, and combinators that allow feature and utility bricks to be seamlessly composed together with clean dependency inversion.

### Available Protocols (7 Types)

```bash
swiftblock snap asyncusecase
swiftblock snap validating
swiftblock snap keyvaluestoring
```

- **`AsyncUseCase`**: `public protocol AsyncUseCase<Input, Output>` with `.withRetry()` and `.withTiming()` decorators.
- **`Logging`**: `public protocol Logging` abstract protocol decoupling services from concrete OSLog/third-party loggers.
- **`KeyValueStoring`**: `public protocol KeyValueStoring` protocol for unified memory, disk, keychain, and tiered cache storage.
- **`Transforming`**: `public protocol Transforming<Source, Target>` for bidirectional mappers and `.pipe()` chaining pipelines.
- **`Validating`**: `public protocol Validating<Input>` with `.and()`, `.or()`, `.not()`, and `AnyValidator` combinators.
- **`ValueFormatting`**: `public protocol ValueFormatting<Input>` for composable string formatting and `.optional()` fallback chains.
- **`DomainValueType`**: `public protocol DomainValueType` standardizing 37 domain value objects and validation.

---

## 6. Structured Composing Engine

SwiftBlock's **Structured Composing Engine** automatically resolves dependencies and offers template flavors when snapping bricks.

### Dependency Resolution
- **Mandatory Dependencies**: Automatically detected and snapped prior to the target brick (e.g. `usecase` automatically snaps `asyncusecase`).
- **Optional Dependencies**: Can be snapped alongside using `--with-optional` or `--all-optional` (e.g. adding `exponentialbackoff` auto-wires `.withRetry()`).
- **Conflict Prevention**: Detects incompatible bricks — both within the resolution plan and against bricks already installed in the project — and prevents conflicting architectures.
- **Idempotency**: Already-snapped dependencies are detected per-file (not per-directory) and skipped automatically, so sharing a folder like `App/Sources/Core/Protocols` never causes bricks to be falsely skipped.

```bash
# Automatically snaps mandatory contract dependencies
swiftblock snap usecase FetchUserProfile

# Snap with optional decorators
swiftblock snap usecase FetchUserProfile --with-optional exponentialbackoff,logger

# Skip automatic dependency resolution
swiftblock snap usecase FetchUserProfile --no-deps
```

### Flavor Selection

Bricks can declare `flavors` in their `brick.yml` — a set of named option groups. Each option can contribute template variables, extra optional dependencies, and additional files when selected.

```yaml
flavors:
  transport:
    prompt: "Select transport style"
    default: sync
    options:
      - id: sync
        title: Synchronous
        variables:
          asyncStyle: false
      - id: async-await
        title: Async Await
        variables:
          asyncStyle: true
        dependencies:
          optional:
            - name: exponentialbackoff
              description: "Auto-retry decorator"
```

```bash
# Choose a flavor option per group
swiftblock snap usecase FetchUserProfile --flavor transport=async-await

# Undeclared keys fall back to plain template variables (legacy behavior)
swiftblock snap usecase FetchUserProfile --flavor timeout=60
```

---

## Next Steps

- Learn how to build [Custom Bricks & Box Registries](file:///Users/ardyan/Development/SwiftBlock/Docs/05-Custom-Bricks-and-Boxes.md).
- See how to compose bricks using [Composition Kits](file:///Users/ardyan/Development/SwiftBlock/Docs/06-Composition-Kits.md).


