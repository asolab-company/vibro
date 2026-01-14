import SwiftUI

struct Home: View {
    @EnvironmentObject var iap: IAPManager
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var overlay: OverlayManager
    @EnvironmentObject var overlaylock: OverlayLock
    @State private var selectedModeID: String? = nil
    @State private var savedModeID: String? = nil

    @State private var selectedLevel: String = "Easy"
    let levels: [String] = ["Easy", "Medium", "Hard"]
    let lockedLevels: Set<String> = ["Medium", "Hard"]

    @State private var selectedIndex = 0
    let icons = ["wind", "lock.fill", "lock.fill", "tornado"]

    @State private var isMainButtonOn = false
    @State private var isLockOn = false

    let modes: [MassageMode] = [
        .init(name: "Pulse", iconName: "ic_pulse", isLocked: false),
        .init(name: "Breeze", iconName: "ic_breze", isLocked: false),
        .init(name: "Storm", iconName: "ic_shtorm", isLocked: true),
        .init(name: "Big Wave", iconName: "ic_wave", isLocked: true),
        .init(name: "Small Wave", iconName: "ic_wave_1", isLocked: true),
        .init(name: "Eruption", iconName: "ic_eruption", isLocked: true),
        .init(name: "Space", iconName: "ic_space", isLocked: true),
        .init(name: "Comet", iconName: "ic_comet", isLocked: true),
        .init(name: "Ship", iconName: "ic_ship", isLocked: true),
        .init(name: "Harp", iconName: "ic_harp", isLocked: true),
        .init(name: "Drums", iconName: "ic_drums", isLocked: true),
        .init(name: "Auger", iconName: "ic_auger", isLocked: true),
    ]

    let columns = [
        GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()),
    ]

    var body: some View {
        ZStack {
            GradientBackgroundView()

            VStack(alignment: .leading, spacing: 10) {

                HStack {
                    Text("VibroMate")
                        .font(.custom("SFProDisplay-Heavy", size: 20))
                        .foregroundColor(.white)

                    Spacer()

                    if !iap.isSubscribed {
                        Button(action: {
                            overlay.show()
                        }) {
                            Image("ic_vip")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 35, height: 35)
                                .padding(8)

                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                }
                .padding(.horizontal, 20)

                DifficultySelectorView()

                CustomSliderView()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        ForEach(modes) { mode in
                            VStack(spacing: 8) {
                                let isUnlocked =
                                    !mode.isLocked || iap.isSubscribed

                                MassageButton(
                                    mode: mode,
                                    isSelected: selectedModeID == mode.id,
                                    isUnlocked: isUnlocked,
                                    action: {
                                        selectedModeID = mode.id

                                        if isMainButtonOn {
                                            if let style = MassageStyle.from(
                                                name: mode.name
                                            ) {
                                                VibrationManager.shared.play(
                                                    style: style
                                                )
                                            }
                                        }
                                    },
                                    onLockedTap: {
                                        overlay.show()
                                    }
                                )

                                Text(mode.name)
                                    .font(
                                        .custom(
                                            "SFProDisplay-Regular",
                                            size: 14
                                        )
                                    )
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.top, 2)
                    .padding(.horizontal, 20)

                }

                Spacer()
                ZStack {
                    GeometryReader { geometry in
                        let screenWidth = geometry.size.width
                        let screenHeight = geometry.size.height

                        ZStack {

                            Button(action: {
                                isMainButtonOn.toggle()

                                if isMainButtonOn {
                                    if let selected = selectedModeID,
                                        let selectedMode = modes.first(where: {
                                            $0.id == selected
                                        }),
                                        let style = MassageStyle.from(
                                            name: selectedMode.name
                                        )
                                    {
                                        VibrationManager.shared.play(
                                            style: style
                                        )
                                    }
                                } else {
                                    VibrationManager.shared.stop()
                                }
                            }) {
                                Image(isMainButtonOn ? "ic_off" : "ic_on")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: screenWidth * 0.45)
                            }
                            .position(x: screenWidth / 2, y: screenHeight / 2)

                            Button(action: {
                                isLockOn.toggle()
                                overlaylock.show()
                            }) {
                                Image(isLockOn ? "ic_off_lock" : "ic_on_lock")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: screenWidth * 0.18)
                            }
                            .position(
                                x: screenWidth / 2 + screenWidth * 0.45 / 2
                                    + screenWidth * 0.10,
                                y: screenHeight / 2
                            )
                        }
                        .frame(width: screenWidth, height: screenHeight)
                    }
                    .frame(height: 200)
                }
                .padding(.bottom, 100)

                Spacer()

            }

            .padding(.top, 20)

        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {

                VibrationManager.shared.stop()
                isMainButtonOn = false
            }
        }
        .onChange(of: overlaylock.isVisible) { visible in
            if visible {

                savedModeID = selectedModeID
                selectedModeID = nil
            } else {

                selectedModeID = savedModeID
                savedModeID = nil
                isLockOn = false
            }
        }
        .onAppear {
            if selectedModeID == nil {
                if let firstAvailable = modes.first(where: {
                    !$0.isLocked || iap.isSubscribed
                }) {
                    selectedModeID = firstAvailable.id
                }
            }
        }
        .onDisappear {
            VibrationManager.shared.stop()
        }

    }
}

private struct MassageButton: View {
    let mode: MassageMode
    let isSelected: Bool
    let isUnlocked: Bool
    let action: () -> Void
    let onLockedTap: () -> Void

    var body: some View {
        Button(action: {
            if isUnlocked {
                action()
            } else {
                onLockedTap()
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                    )

                Image(mode.iconName)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .scaledToFit()
                    .frame(width: 38, height: 38)

                if !isUnlocked {
                    VStack {
                        HStack {
                            Spacer()
                            Image("ic_lock")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .padding(5)
                                .offset(x: 9, y: -6)
                        }
                        Spacer()
                    }
                    .frame(width: 70, height: 70)
                }
            }
        }
    }
}

struct DifficultySelectorView: View {
    @State private var selected: Difficulty = .easy
    @EnvironmentObject var iap: IAPManager

    enum Difficulty: String, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Difficulty.allCases, id: \.self) { level in
                ZStack {
                    if selected == level {
                        Rectangle()
                            .fill(Color.white)
                            .clipShape(cornerShape(for: level))
                            .frame(height: 38)
                    } else {
                        Rectangle()
                            .fill(backgroundColor(for: level))
                            .clipShape(cornerShape(for: level))
                            .frame(height: 38)
                    }

                    HStack(spacing: 6) {
                        Text(level.rawValue)
                            .foregroundColor(
                                selected == level
                                    ? Color(hex: "AC57A7") : .white
                            )
                            .font(.custom("SFProDisplay-Regular", size: 16))

                        if isLocked(level) {
                            Image("ic_lock")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.purple)
                        }
                    }
                    .padding(.horizontal, 10)
                }
                .frame(maxWidth: .infinity, minHeight: 38, maxHeight: 38)
                .contentShape(Rectangle())
                .onTapGesture {
                    if !isLocked(level) {
                        selected = level
                        VibrationSettings.shared.intensity = intensityForLevel(
                            level
                        )
                    }
                }
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .frame(height: 46)
        .padding(.horizontal, 20)
    }

    private func isLocked(_ level: Difficulty) -> Bool {
        level != .easy && !iap.isSubscribed
    }

    private func backgroundColor(for level: Difficulty) -> Color {
        switch level {
        case .easy:
            return Color(hex: "FFFFFF").opacity(0.4)
        case .medium:
            return Color(hex: "FFFFFF").opacity(0.3)
        case .hard:
            return Color(hex: "FFFFFF").opacity(0.2)
        }
    }
    private func cornerShape(for level: Difficulty) -> some Shape {
        return AnyShape(
            RoundedCorner(
                radius: 23,
                corners: [.topLeft, .topRight, .bottomLeft, .bottomRight]
            )
        )
    }

    private func intensityForLevel(_ level: Difficulty) -> VibrationIntensity {
        switch level {
        case .easy: return .light
        case .medium: return .medium
        case .hard: return .strong
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = 10.0
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct CustomSliderView: View {
    @ObservedObject private var settings = VibrationSettings.shared
    @EnvironmentObject var iap: IAPManager
    var body: some View {
        VStack {
            HStack(spacing: 16) {
                Image("ic_s_left")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.white)
                    .padding(.leading, 12)

                GeometryReader { geometry in
                    let width = geometry.size.width

                    ZStack(alignment: .leading) {

                        Capsule()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 8)

                        Capsule()
                            .fill(Color.white)
                            .frame(
                                width: CGFloat(settings.speed / 2.0) * width,
                                height: 8
                            )

                        if !iap.isSubscribed {
                            Image("ic_lock")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 24, height: 24)
                                .position(x: width / 2, y: 14)

                            Image("ic_lock")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 24, height: 24)
                                .position(x: width - 10, y: 14)
                        }

                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 26, height: 26)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 20, height: 20)

                            Circle()
                                .stroke(Color.purple, lineWidth: 4)
                                .frame(width: 20, height: 20)
                        }
                        .offset(
                            x: CGFloat(settings.speed / 2.0) * width - 17
                        )

                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let newValue = gesture.location.x / width
                                let clampedValue = min(
                                    max(0, newValue),
                                    iap.isSubscribed ? 1.0 : 0.4
                                )
                                settings.speed = Float(clampedValue * 2.0)
                            }
                    )
                }
                .frame(height: 28)
                .padding(.horizontal, 5)

                Image("ic_s_right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.white)
                    .padding(.trailing, 12)
            }
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .padding(.horizontal, 20)
        }
    }
}

struct SubtleBlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {

        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.backgroundColor = .clear
        blurView.alpha = 0.7
        return blurView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct CustomTopRoundedShape: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let curveHeight: CGFloat = radius

        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.midX - radius, y: 0))
        path.addArc(
            center: CGPoint(x: rect.midX, y: 0),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}

#Preview {
    Home()
        .environmentObject(IAPManager.shared)
}
