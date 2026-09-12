import Foundation

/// Health validation failure details.
public enum HealthValidationError: Error, Equatable, Sendable {
    case invalidHeartRate(bpm: Int)
    case invalidBloodPressure(systolic: Int, diastolic: Int)
    case invalidBodyTemperature(celsius: Double)
    case invalidBMI(value: Double)
    case invalidBloodGlucose(mgDL: Double)
}

/// Defines standard interface for physiological metrics validation.
public protocol HealthValidatorProtocol: Sendable {
    func validateHeartRate(_ bpm: Int) -> Bool
    func validateBloodPressure(systolic: Int, diastolic: Int) -> Bool
    func validateBodyTemperature(celsius: Double) -> Bool
    func validateBMI(_ bmi: Double) -> Bool
    func validateBloodGlucose(_ mgDL: Double) -> Bool
}

/// Thread-safe physiological metrics validator implementing `HealthValidatorProtocol`.
public final class __MODULE_NAME__: HealthValidatorProtocol {
    /// Shared singleton instance.
    public static let shared = __MODULE_NAME__()

    public init() {}

    /// Validates heart rate in beats per minute (physiological range 30-220 bpm).
    public func validateHeartRate(_ bpm: Int) -> Bool {
        return (30...220).contains(bpm)
    }

    /// Validates blood pressure reading (systolic 60-250, diastolic 40-150, systolic > diastolic).
    public func validateBloodPressure(systolic: Int, diastolic: Int) -> Bool {
        guard (60...250).contains(systolic) else { return false }
        guard (40...150).contains(diastolic) else { return false }
        return systolic > diastolic
    }

    /// Validates body temperature in Celsius (physiological range 35.0°C - 42.0°C).
    public func validateBodyTemperature(celsius: Double) -> Bool {
        return (35.0...42.0).contains(celsius)
    }

    /// Validates Body Mass Index (BMI range 10.0 - 60.0 kg/m²).
    public func validateBMI(_ bmi: Double) -> Bool {
        return (10.0...60.0).contains(bmi)
    }

    /// Validates blood glucose level in mg/dL (physiological range 20.0 - 600.0 mg/dL).
    public func validateBloodGlucose(_ mgDL: Double) -> Bool {
        return (20.0...600.0).contains(mgDL)
    }
}
