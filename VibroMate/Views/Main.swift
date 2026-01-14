import SwiftUI

struct Main: View {
    @State private var selectedTab: Tab = .center
    @EnvironmentObject var overlay: OverlayManager
    @EnvironmentObject var overlaylock: OverlayLock
    @State private var showOverlay = false
    @EnvironmentObject var iap: IAPManager

    var body: some View {
        ZStack(alignment: .bottom) {
            switch selectedTab {
            case .massages:
                Massages()
            case .settings:
                Settings()
            case .center:
                Home()
            }

            CustomTabBarView(selectedTab: $selectedTab)

            SwipeUnlockOverlay(isVisible: $overlaylock.isVisible)
        }
        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: $overlay.showPaywall) {
            PayWall()
        }
        .fullScreenCover(isPresented: $overlay.isOverlayVisible) {
            PayWall()
        }
        .onAppear {
            if !iap.isSubscribed {
                overlay.isOverlayVisible = true
            }
        }
    }
}

enum Tab {
    case massages, center, settings
}

struct CustomTabBarView: View {
    @Binding var selectedTab: Tab

    var body: some View {
        ZStack {

            Color.white
                .frame(height: 80)
                .offset(y: 50)
                .ignoresSafeArea(.all, edges: .bottom)

            TabBarShape()
                .fill(Color.white)

                .frame(height: 80)
                .overlay(
                    HStack {
                        tabButton(
                            image: "ic_wand",
                            text: "Massages",
                            tab: .massages
                        )
                        Spacer()
                        tabButton(
                            image: "ic_settings",
                            text: "Settings",
                            tab: .settings
                        )
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 5)
                )

            Button(action: {
                selectedTab = .center
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 76, height: 76)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

                    Image("ic_waves")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 45, height: 45)
                        .foregroundColor(
                            selectedTab == .center
                                ? Color(hex: "#AC57A7")
                                : .gray
                        )

                }
            }
            .offset(y: -40)
        }
        .frame(height: 70)
    }

    @ViewBuilder
    private func tabButton(image: String, text: String, tab: Tab) -> some View {
        let isSelected = selectedTab == tab
        let color = isSelected ? Color(hex: "#AC57A7") : .gray

        Button(action: {
            selectedTab = tab
        }) {
            VStack(spacing: 4) {
                Image(image)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 35, height: 35)
                    .foregroundColor(color)

                Text(text)
                    .font(.custom("SFProDisplay-Regular", size: 12))
                    .foregroundColor(color)
            }
        }
    }
}

struct TabBarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let center = rect.midX
        let radius: CGFloat = 50
        let curveInset: CGFloat = 8
        let cornerRadius: CGFloat = 36

        path.move(to: CGPoint(x: 0, y: cornerRadius))
        path.addArc(
            center: CGPoint(x: cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: center - radius - curveInset, y: 0))

        path.addArc(
            center: CGPoint(x: center, y: 0),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: true
        )

        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))

        path.addArc(
            center: CGPoint(x: rect.width - cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(270),
            endAngle: .degrees(0),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}

struct SwipeUnlockOverlay: View {
    @Binding var isVisible: Bool
    @GestureState private var dragOffset = CGSize.zero

    var body: some View {
        if isVisible {
            ZStack {
                SubtleBlurView()
                    .ignoresSafeArea()

                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "000000").opacity(0.8),
                                    Color(hex: "000000").opacity(0.5),
                                    Color(hex: "000000").opacity(0.2),
                                    .clear,
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: UIScreen.main.bounds.height * 1.5)
                        .offset(y: 250)

                    VStack {

                        VStack(spacing: 10) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            Text("Swipe Up\nTo Unlock")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }

                        Spacer()

                        Image("ic_unlock")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)

                        Spacer()
                    }
                    .padding(.top, 300)

                }
                .ignoresSafeArea(edges: .bottom)
                .offset(y: dragOffset.height < 0 ? dragOffset.height : 0)
                .animation(.easeOut(duration: 0.2), value: dragOffset)
                .gesture(
                    DragGesture()
                        .updating(
                            $dragOffset,
                            body: { value, state, _ in
                                state = value.translation
                            }
                        )
                        .onEnded { value in
                            if value.translation.height < -100 {
                                withAnimation {
                                    isVisible = false
                                }
                            }
                        }
                )
            }
            .transition(.move(edge: .bottom))
            .animation(.easeInOut, value: isVisible)
        }
    }
}

#Preview {
    Main()
}
