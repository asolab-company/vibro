import Combine
import Foundation

final class VibrationSettings: ObservableObject {

    static let shared = VibrationSettings()

    @Published var intensity: VibrationIntensity {
        didSet {
            UserDefaults.standard.set(
                intensity.rawValue,
                forKey: Self.intensityKey
            )
        }
    }

    @Published var speed: Float {
        didSet { UserDefaults.standard.set(speed, forKey: Self.speedKey) }
    }

    private static let intensityKey = "vibration_intensity"
    private static let speedKey = "vibration_speed"

    private init() {

        if let stored = UserDefaults.standard.object(forKey: Self.intensityKey)
            as? Float,
            let saved = VibrationIntensity(rawValue: stored)
        {
            intensity = saved
        } else {
            intensity = .light
        }

        if let stored = UserDefaults.standard.object(forKey: Self.speedKey)
            as? Float
        {
            speed = stored
        } else {
            speed = 0.5
        }
    }
}
