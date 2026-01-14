import SwiftUI

struct MassageMode: Identifiable {
    let id: String
    let name: String
    let iconName: String
    let isLocked: Bool

    init(name: String, iconName: String, isLocked: Bool) {
        self.id = name
        self.name = name
        self.iconName = iconName
        self.isLocked = isLocked
    }
}
struct Massages: View {
    @EnvironmentObject var overlay: OverlayManager
    @EnvironmentObject var iap: IAPManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedModeID: String? = nil

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

            VStack(alignment: .leading, spacing: 30) {
                Text("Massages")
                    .font(.custom("SFProDisplay-Regular", size: 20))
                    .foregroundColor(.white)

                LazyVGrid(
                    columns: columns,
                    spacing: UIScreen.main.bounds.height * 0.03
                ) {
                    ForEach(modes) { mode in
                        VStack(spacing: 8) {
                            let isUnlocked = !mode.isLocked || iap.isSubscribed

                            MassageButton(
                                mode: mode,
                                isSelected: selectedModeID == mode.id,
                                isUnlocked: isUnlocked,
                                action: {
                                    if selectedModeID == mode.id {
                                        selectedModeID = nil
                                        VibrationManager.shared.stop()
                                    } else {
                                        selectedModeID = mode.id
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
                                .font(.custom("SFProDisplay-Regular", size: 14))
                                .foregroundColor(.white)
                        }
                    }
                }

                Spacer()

            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background || newPhase == .inactive {
                selectedModeID = nil
                VibrationManager.shared.stop()
            }
        }
        .onDisappear {
            selectedModeID = nil
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

#Preview {
    Massages()
        .environmentObject(IAPManager.shared)
}
