import Foundation

enum VibrationIntensity: Float, CaseIterable, Identifiable {
    case light = 0.6
    case medium = 0.8
    case strong = 1.0

    var id: Self { self }
}
