import CoreHaptics
import Foundation

final class VibrationManager {

    static let shared = VibrationManager()
    private init() { prepareHaptics() }

    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    private let settings = VibrationSettings.shared

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            return
        }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptics engine error: \(error)")
        }
    }

    func stop() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        try? engine?.stop()
    }

    func play(style: MassageStyle) {
        stop()
        prepareHaptics()

        guard let engine else { return }

        do {
            let pattern = try CHHapticPattern(
                events: style.events,
                parameters: []
            )
            let advancedPlayer = try engine.makeAdvancedPlayer(with: pattern)
            advancedPlayer.loopEnabled = true

            advancedPlayer.playbackRate = settings.speed

            let intensityParam = CHHapticDynamicParameter(
                parameterID: .hapticIntensityControl,
                value: settings.intensity.rawValue,
                relativeTime: 0
            )
            try advancedPlayer.sendParameters([intensityParam], atTime: 0)

            try advancedPlayer.start(atTime: CHHapticTimeImmediate)
            player = advancedPlayer
        } catch {
            print("Haptic pattern error: \(error)")
        }
    }
}
