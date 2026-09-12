import Foundation

/// Defines standard interface for health and fitness metrics formatting.
public protocol HealthFormatterProtocol: Sendable {
    func formatSteps(_ steps: Int, locale: Locale) -> String
    func formatEnergy(calories: Double, locale: Locale) -> String
    func formatDistance(meters: Double, locale: Locale) -> String
    func formatWeight(kilograms: Double, locale: Locale) -> String
    func formatHeartRate(_ bpm: Int) -> String
    func formatBloodPressure(systolic: Int, diastolic: Int) -> String
}

/// Thread-safe health and fitness metrics formatter implementing `HealthFormatterProtocol`.
public final class __MODULE_NAME__: @unchecked Sendable, HealthFormatterProtocol {
    /// Shared singleton instance.
    public static let shared = __MODULE_NAME__()

    private let lock = NSLock()
    private let energyFormatter: EnergyFormatter
    private let lengthFormatter: LengthFormatter
    private let massFormatter: MassFormatter
    private let numberFormatter: NumberFormatter

    public init() {
        let energy = EnergyFormatter()
        energy.isForFoodEnergyUse = true

        let length = LengthFormatter()
        length.isForPersonHeightUse = false

        let mass = MassFormatter()
        mass.isForPersonMassUse = true

        let number = NumberFormatter()
        number.numberStyle = .decimal

        self.energyFormatter = energy
        self.lengthFormatter = length
        self.massFormatter = mass
        self.numberFormatter = number
    }

    /// Formats step count into localized string (e.g. "10,452 steps").
    public func formatSteps(_ steps: Int, locale: Locale = .current) -> String {
        lock.lock()
        defer { lock.unlock() }
        numberFormatter.locale = locale
        let formatted = numberFormatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
        return "\(formatted) steps"
    }

    /// Formats energy in kilocalories into localized energy string (e.g. "2,450 kcal").
    public func formatEnergy(calories: Double, locale: Locale = .current) -> String {
        lock.lock()
        defer { lock.unlock() }
        energyFormatter.numberFormatter.locale = locale
        return energyFormatter.string(fromJoules: calories * 4184.0)
    }

    /// Formats distance in meters into localized length string (e.g. "5.4 km" or "3.3 mi").
    public func formatDistance(meters: Double, locale: Locale = .current) -> String {
        lock.lock()
        defer { lock.unlock() }
        lengthFormatter.numberFormatter.locale = locale
        return lengthFormatter.string(fromMeters: meters)
    }

    /// Formats weight in kilograms into localized weight string (e.g. "72.5 kg" or "160 lbs").
    public func formatWeight(kilograms: Double, locale: Locale = .current) -> String {
        lock.lock()
        defer { lock.unlock() }
        massFormatter.numberFormatter.locale = locale
        return massFormatter.string(fromKilograms: kilograms)
    }

    /// Formats heart rate in beats per minute (e.g. "72 bpm").
    public func formatHeartRate(_ bpm: Int) -> String {
        return "\(bpm) bpm"
    }

    /// Formats blood pressure reading (e.g. "120/80 mmHg").
    public func formatBloodPressure(systolic: Int, diastolic: Int) -> String {
        return "\(systolic)/\(diastolic) mmHg"
    }
}
