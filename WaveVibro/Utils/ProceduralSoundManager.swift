import AVFoundation
import Foundation

/// Native procedural versions of the twelve WaveVibro sound worlds used on the website.
/// Audio is generated locally, kept in memory only, and loops while its haptic mode is active.
final class ProceduralSoundManager {
    static let shared = ProceduralSoundManager()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var activeBuffer: AVAudioPCMBuffer?
    private let sampleRate = 44_100.0
    private let loopDuration = 12.0

    private init() {
        engine.attach(player)
    }

    func play(style: MassageStyle) {
        stop()

        guard let buffer = makeBuffer(for: style) else { return }
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            engine.disconnectNodeOutput(player)
            engine.connect(player, to: engine.mainMixerNode, format: buffer.format)
            engine.prepare()
            try engine.start()

            activeBuffer = buffer
            player.volume = 0.72
            player.scheduleBuffer(buffer, at: nil, options: [.loops, .interrupts])
            player.play()
        } catch {
            stop()
        }
    }

    func stop() {
        player.stop()
        engine.stop()
        activeBuffer = nil
    }

    private func makeBuffer(for style: MassageStyle) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 2
        ) else { return nil }

        let frameCount = AVAudioFrameCount(sampleRate * loopDuration)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ), let channels = buffer.floatChannelData else { return nil }

        buffer.frameLength = frameCount
        var noise = SeededNoise(seed: UInt64(style.rawValue.hashValue.magnitude) + 1)
        var smoothNoise = 0.0
        var bandNoise = 0.0
        let fadeFrames = max(1, Int(sampleRate * 0.04))

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let white = noise.next()
            smoothNoise = smoothNoise * 0.985 + white * 0.015
            bandNoise = bandNoise * 0.82 + (white - smoothNoise) * 0.18

            var (left, right) = sample(
                for: style,
                time: time,
                whiteNoise: white,
                smoothNoise: smoothNoise,
                bandNoise: bandNoise
            )

            let edgeFade: Double
            if frame < fadeFrames {
                edgeFade = Double(frame) / Double(fadeFrames)
            } else if frame >= Int(frameCount) - fadeFrames {
                edgeFade = Double(Int(frameCount) - frame - 1) / Double(fadeFrames)
            } else {
                edgeFade = 1
            }

            left = min(0.95, max(-0.95, left * edgeFade))
            right = min(0.95, max(-0.95, right * edgeFade))
            channels[0][frame] = Float(left)
            channels[1][frame] = Float(right)
        }

        return buffer
    }

    private func sample(
        for style: MassageStyle,
        time: Double,
        whiteNoise: Double,
        smoothNoise: Double,
        bandNoise: Double
    ) -> (Double, Double) {
        switch style {
        case .pulse:
            let envelope = pow(positiveSine(rate: 1.08, time: time), 3.2)
            let value = sine(58, time) * (0.025 + envelope * 0.28)
                + sine(116, time) * (0.01 + envelope * 0.085)
            return stereo(value * 0.78)

        case .breeze:
            let breath = pow(positiveSine(rate: 0.12, time: time), 1.7)
            let value = bandNoise * (0.05 + breath * 0.36)
                + sine(174, time) * (0.015 + breath * 0.07)
            return (value * 0.72, value * 0.68)

        case .storm:
            let rumble = smoothNoise * (0.34 + positiveSine(rate: 0.18, time: time) * 0.22)
            let rain = whiteNoise * (0.025 + positiveSine(rate: 0.43, time: time) * 0.025)
            let thunder = sine(43, time) * (0.04 + positiveSine(rate: 0.09, time: time) * 0.08)
            return stereo((rumble + rain + thunder) * 0.72)

        case .bigWave:
            let wave = pow(positiveSine(rate: 0.075, time: time), 2.4)
            return stereo(smoothNoise * (0.045 + wave * 0.58))

        case .smallWave:
            let wave = pow(positiveSine(rate: 0.19, time: time), 2.0)
            return stereo(bandNoise * (0.06 + wave * 0.34))

        case .eruption:
            let ground = smoothNoise * (0.26 + positiveSine(rate: 0.31, time: time) * 0.24)
            let heat = saw(46, time) * (0.035 + positiveSine(rate: 0.17, time: time) * 0.055)
            return stereo((ground + heat) * 0.72)

        case .space:
            let left = sine(110, time) * (0.07 + positiveSine(rate: 0.08, time: time) * 0.05)
                + sine(164.81, time, phase: -0.08) * (0.045 + positiveSine(rate: 0.11, time: time) * 0.035)
                + sine(220, time, phase: 0.12) * 0.03
            let right = sine(110, time, phase: 0.05) * (0.07 + positiveSine(rate: 0.08, time: time) * 0.05)
                + sine(164.81, time, phase: 0.08) * (0.045 + positiveSine(rate: 0.11, time: time) * 0.035)
                + sine(220, time, phase: -0.12) * 0.03
            return (left, right)

        case .comet:
            let position = time.truncatingRemainder(dividingBy: 3.1)
            guard position < 2.35 else { return (0, 0) }
            let attack = min(1, position / 0.35)
            let release = max(0, 1 - max(0, position - 0.35) / 2.0)
            let frequency: Double
            if position <= 1.2 {
                frequency = 180 * pow(1_350 / 180, position / 1.2)
            } else {
                frequency = 1_350 * pow(340 / 1_350, (position - 1.2) / 1.15)
            }
            let value = sine(frequency, time) * attack * release * 0.19
            return (value * 0.75, value)

        case .ship:
            let enginePulse = 0.55 + positiveSine(rate: 3.8, time: time) * 0.45
            let motorPulse = 0.55 + positiveSine(rate: 7.6, time: time) * 0.45
            let value = saw(52, time) * enginePulse * 0.11
                + square(104, time) * motorPulse * 0.028
            return stereo(value)

        case .harp:
            let notes = [261.63, 329.63, 392.0, 523.25, 659.25]
            let position = time.truncatingRemainder(dividingBy: 3.6)
            var value = 0.0
            for (index, frequency) in notes.enumerated() {
                let elapsed = position - Double(index) * 0.42
                guard elapsed >= 0, elapsed < 1.15 else { continue }
                let attack = min(1, elapsed / 0.025)
                let release = exp(-3.8 * elapsed)
                value += sine(frequency, time) * attack * release * 0.28
            }
            return (value * 0.82, value)

        case .drums:
            let beatLength = 0.76
            let position = time.truncatingRemainder(dividingBy: beatLength)
            let beat = Int(time / beatLength)
            let frequency = 48 + 97 * exp(-14 * position)
            let kick = sine(frequency, time) * exp(-11 * position) * 0.62
            let snare = beat.isMultiple(of: 2) ? 0 : whiteNoise * exp(-24 * position) * 0.18
            return stereo(kick + snare)

        case .auger:
            let pulse = 0.45 + positiveSine(rate: 8.2, time: time) * 0.55
            let value = saw(84, time) * pulse * 0.11 + bandNoise * pulse * 0.13
            return stereo(value)
        }
    }

    private func stereo(_ value: Double) -> (Double, Double) {
        (value, value)
    }

    private func positiveSine(rate: Double, time: Double) -> Double {
        (sin(2 * .pi * rate * time) + 1) * 0.5
    }

    private func sine(_ frequency: Double, _ time: Double, phase: Double = 0) -> Double {
        sin(2 * .pi * frequency * time + phase)
    }

    private func saw(_ frequency: Double, _ time: Double) -> Double {
        2 * (frequency * time - floor(frequency * time + 0.5))
    }

    private func square(_ frequency: Double, _ time: Double) -> Double {
        sine(frequency, time) >= 0 ? 1 : -1
    }
}

private struct SeededNoise {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        let normalized = Double(state >> 11) / Double(1 << 53)
        return normalized * 2 - 1
    }
}
