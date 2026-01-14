import CoreHaptics

enum MassageStyle: String, CaseIterable {

    case pulse, breeze, storm, bigWave, smallWave,
        eruption, space, comet, ship, harp, drums, auger

    var events: [CHHapticEvent] {
        switch self {

        case .pulse:
            return [
                Self.beat(time: 0.00, intensity: 1.0),
                Self.beat(time: 0.18, intensity: 0.8),
                Self.beat(time: 0.50, intensity: 1.0),
                Self.beat(time: 0.68, intensity: 0.8),
            ]

        case .harp:
            return [
                Self.beat(time: 0.00, intensity: 0.5, sharp: 0.40),
                Self.beat(time: 0.12, intensity: 0.4, sharp: 0.35),
                Self.beat(time: 0.24, intensity: 0.3, sharp: 0.30),
                Self.beat(time: 0.40, intensity: 0.25, sharp: 0.25),
            ]

        case .drums:
            return stride(from: 0.0, through: 1.05, by: 0.35).map {
                Self.beat(time: $0, intensity: 1.0, sharp: 0.9)
            }

        case .breeze:
            return Self.wave(start: 0.00, duration: 1.2, from: 0.15, to: 0.75)
                + Self.wave(start: 1.60, duration: 1.2, from: 0.15, to: 0.75)

        case .ship:
            return stride(from: 0.0, through: 2.0, by: 1.0).flatMap { t in
                Self.wave(start: t, duration: 0.8, from: 0.5, to: 0.9)
            }

        case .bigWave:
            return Self.wave(start: 0.0, duration: 1.2, from: 0.4, to: 1.0)
                + Self.wave(start: 1.4, duration: 1.2, from: 0.4, to: 1.0)

        case .smallWave:
            return stride(from: 0.0, through: 1.8, by: 0.9).flatMap { t in
                Self.wave(start: t, duration: 0.6, from: 0.3, to: 0.6)
            }

        case .storm:
            return (0..<6).map { i in
                Self.beat(time: Double(i) * 0.10, intensity: 1.0, sharp: 1.0)
            }

        case .eruption:
            return (0..<4).flatMap { i in
                let base = Double(i) * 0.35
                return [
                    Self.beat(time: base, intensity: 1.0, sharp: 0.85),
                    Self.beat(time: base + 0.1, intensity: 1.0, sharp: 0.85),
                ]
            }

        case .auger:
            return Self.wave(
                start: 0.0,
                duration: 0.6,
                from: 0.8,
                to: 1.0,
                sharp: 0.9
            )
                + Self.wave(
                    start: 1.0,
                    duration: 0.6,
                    from: 0.8,
                    to: 1.0,
                    sharp: 0.9
                )

        case .space:
            return [
                Self.beat(time: 0.0, intensity: 0.18, sharp: 0.1),
                Self.beat(time: 1.8, intensity: 0.18, sharp: 0.1),
                Self.beat(time: 3.6, intensity: 0.18, sharp: 0.1),
            ]

        case .comet:
            return [
                Self.beat(time: 0.00, intensity: 0.9, sharp: 0.7),
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(
                            parameterID: .hapticIntensity,
                            value: 0.35
                        ),
                        CHHapticEventParameter(
                            parameterID: .hapticSharpness,
                            value: 0.25
                        ),
                    ],
                    relativeTime: 0.12,
                    duration: 0.50
                ),
            ]
        }
    }

    private static func beat(
        time: Double,
        intensity: Float,
        sharp: Float = 0.8
    ) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(
                    parameterID: .hapticIntensity,
                    value: intensity
                ),
                CHHapticEventParameter(
                    parameterID: .hapticSharpness,
                    value: sharp
                ),
            ],
            relativeTime: time
        )
    }

    private static func wave(
        start: Double,
        duration: Double,
        from: Float,
        to: Float,
        sharp: Float = 0.3
    ) -> [CHHapticEvent] {

        let riseDur = duration * 0.30
        let peakDur = duration * 0.40
        let fallDur = duration - riseDur - peakDur

        return [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(
                        parameterID: .hapticIntensity,
                        value: from
                    ),
                    CHHapticEventParameter(
                        parameterID: .hapticSharpness,
                        value: sharp
                    ),
                ],
                relativeTime: start,
                duration: riseDur
            ),
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(
                        parameterID: .hapticIntensity,
                        value: to
                    ),
                    CHHapticEventParameter(
                        parameterID: .hapticSharpness,
                        value: sharp
                    ),
                ],
                relativeTime: start + riseDur,
                duration: peakDur
            ),
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(
                        parameterID: .hapticIntensity,
                        value: from
                    ),
                    CHHapticEventParameter(
                        parameterID: .hapticSharpness,
                        value: sharp
                    ),
                ],
                relativeTime: start + riseDur + peakDur,
                duration: fallDur
            ),
        ]
    }

    static func from(name: String) -> MassageStyle? {
        Self.allCases.first { $0.rawValue.lowercased() == name.lowercased() }
    }
}
