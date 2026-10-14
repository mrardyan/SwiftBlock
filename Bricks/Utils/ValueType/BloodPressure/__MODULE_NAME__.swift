import Foundation

/// Errors thrown by blood pressure validation.
public enum BloodPressureError: Error, Equatable, Sendable {
    case invalidReadings(systolic: Int, diastolic: Int)
}

/// Blood pressure medical classification (AHA standards).
public enum BloodPressureCategory: String, Codable, Equatable, Sendable {
    case normal = "Normal"
    case elevated = "Elevated"
    case hypertensionStage1 = "Hypertension Stage 1"
    case hypertensionStage2 = "Hypertension Stage 2"
    case hypertensiveCrisis = "Hypertensive Crisis"
}

/// Type-safe representation of blood pressure (systolic / diastolic mmHg).
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable {
    public let systolic: Int
    public let diastolic: Int

    public init(systolic: Int, diastolic: Int) throws {
        guard (60...300).contains(systolic), (40...200).contains(diastolic), systolic > diastolic else {
            throw BloodPressureError.invalidReadings(systolic: systolic, diastolic: diastolic)
        }
        self.systolic = systolic
        self.diastolic = diastolic
    }

    /// Medical classification per AHA guidelines.
    public var category: BloodPressureCategory {
        if systolic >= 180 || diastolic >= 120 {
            return .hypertensiveCrisis
        } else if systolic >= 140 || diastolic >= 90 {
            return .hypertensionStage2
        } else if (130...139).contains(systolic) || (80...89).contains(diastolic) {
            return .hypertensionStage1
        } else if (120...129).contains(systolic) && diastolic < 80 {
            return .elevated
        } else {
            return .normal
        }
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        let sys = formatter.string(from: NSNumber(value: systolic)) ?? "\(systolic)"
        let dia = formatter.string(from: NSNumber(value: diastolic)) ?? "\(diastolic)"
        return "\(sys)/\(dia) mmHg"
    }
}
