import SwiftUI

struct Onboarding: View {
    @State private var currentTab = 0
    var onFinish: () -> Void

    var body: some View {
        ZStack {

            TabView(selection: $currentTab) {
                OnboardingScreen1()
                    .tag(0)
                OnboardingScreen2()
                    .tag(1)
                OnboardingScreen3()
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .background(
                ZStack(alignment: .top) {
                    Color(hex: "FFF9FD").ignoresSafeArea()
                    Image("onb_top")
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                }
            )
            .ignoresSafeArea()
            .overlay(
                VStack {
                    Spacer()

                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(
                                    index == currentTab
                                        ? Color(hex: "#A75AAC")
                                        : Color.gray.opacity(0.4)
                                )
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.bottom, 10)

                    Button(action: {
                        if currentTab < 2 {
                            currentTab += 1
                        } else {
                            UserDefaults.standard.set(
                                true,
                                forKey: "onboarding_passed"
                            )
                            onFinish()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Continue")
                                .foregroundColor(.white)
                                .font(.custom("SFProDisplay-Bold", size: 18))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color(hex: "#AC57A7"))
                        .cornerRadius(40)
                    }
                    .frame(height: 55)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 10)

                    VStack(spacing: 2) {
                        Text("By Proceeding You Accept")
                            .foregroundColor(Color(hex: "BABABA"))
                            .font(.custom("SFProDisplay-Medium", size: 13))
                        HStack(spacing: 4) {
                            Text("Our")
                                .foregroundColor(Color(hex: "BABABA"))
                                .font(.custom("SFProDisplay-Medium", size: 13))
                            Button(action: {
                                UIApplication.shared.open(Constants.termsURL)
                            }) {
                                Text("Terms Of Use")
                                    .foregroundColor(Color(hex: "#AC57A7"))
                                    .font(
                                        .custom("SFProDisplay-Medium", size: 13)
                                    )
                            }
                            Text("And")
                                .foregroundColor(Color(hex: "BABABA"))
                                .font(.custom("SFProDisplay-Medium", size: 13))
                            Button(action: {
                                UIApplication.shared.open(Constants.privacyURL)
                            }) {
                                Text("Privacy Policy")
                                    .foregroundColor(Color(hex: "#AC57A7"))
                                    .font(
                                        .custom("SFProDisplay-Medium", size: 13)
                                    )
                            }
                        }
                    }
                    .opacity(currentTab == 0 ? 1 : 0)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
                }
            )

        }

    }
}

struct OnboardingScreen1: View {
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            VStack(spacing: height * 0.04) {

                VStack(spacing: height * 0.02) {
                    Image("app_bg_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: width * 0.35)

                    Text("Welcome to\nthe VibroMate")
                        .font(
                            .custom(
                                "SFProDisplay-Heavy",
                                size: width * 0.065,
                                relativeTo: .title
                            )
                        )
                        .foregroundColor(Color(hex: "AC57A7"))
                        .multilineTextAlignment(.center)
                        .dynamicTypeSize(.medium ... .xxLarge)
                        .frame(maxWidth: .infinity)
                }.padding(.top, height * 0.02)

                VStack(alignment: .leading, spacing: height * 0.03) {
                    InfoRow(
                        icon: "ic_time",
                        iconColor: Color(hex: "#A75AAC"),
                        title: "Pre-programmed Sessions",
                        description:
                            "Take advantage of pre-programmed sessions, specially designed for you."
                    )

                    InfoRow(
                        icon: "ic_bolt",
                        iconColor: Color(hex: "#A75AAC"),
                        title: "Intensity Control",
                        description:
                            "Easily adjust the intensity of massage sessions to match your comfort level."
                    )

                    InfoRow(
                        icon: "ic_speed",
                        iconColor: Color(hex: "#A75AAC"),
                        title: "Speed Control",
                        description:
                            "Easily change the speed of massage patterns to get the best experience."
                    )
                }
                .padding(width * 0.05)
                .background(Color(hex: "#AC57A7").opacity(0.2))
                .cornerRadius(24)
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding(.horizontal, width * 0.05)
        }
    }
}

struct OnboardingScreen2: View {
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            VStack(spacing: height * 0.04) {

                VStack(spacing: height * 0.02) {
                    Image("onb_2")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: height * 0.57)

                    Text("Stay in\nControl")
                        .font(
                            .custom(
                                "SFProDisplay-Heavy",
                                size: width * 0.065,
                                relativeTo: .title
                            )
                        )
                        .foregroundColor(Color(hex: "AC57A7"))
                        .multilineTextAlignment(.center)
                        .dynamicTypeSize(.medium ... .xxLarge)
                        .frame(maxWidth: .infinity)

                    Text(
                        "Use screen lock to prevent accidental interruptions and enjoy uninterrupted relaxation."
                    )
                    .font(.custom("SFProDisplay-Regular", size: 14))
                    .foregroundColor(Color(hex: "#000000"))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                }

                Spacer()
            }
            .padding(.horizontal, width * 0.05)
        }
    }
}

struct OnboardingScreen3: View {
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            VStack(spacing: height * 0.04) {

                VStack(spacing: height * 0.02) {
                    Image("onb_3")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: height * 0.57)

                    Text("Customize your\nexperience")
                        .font(
                            .custom(
                                "SFProDisplay-Heavy",
                                size: width * 0.065,
                                relativeTo: .title
                            )
                        )
                        .foregroundColor(Color(hex: "AC57A7"))
                        .multilineTextAlignment(.center)
                        .dynamicTypeSize(.medium ... .xxLarge)
                        .frame(maxWidth: .infinity)

                    Text(
                        "Choose from 12 unique vibration modes and easily adjust the speed and intensity to match your mood."
                    )
                    .font(.custom("SFProDisplay-Regular", size: 14))
                    .foregroundColor(Color(hex: "#000000"))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                }

                Spacer()
            }
            .padding(.horizontal, width * 0.05)
        }
    }
}

struct InfoRow: View {
    var icon: String
    var iconColor: Color
    var title: String
    var description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {

                Image(icon)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .bold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("SFProDisplay-Heavy", size: 16))
                    .foregroundColor(Color(hex: "#AC57A7"))
                    .shadow(color: .white.opacity(0.8), radius: 1, x: 0, y: 1)

                Text(description)
                    .font(.custom("SFProDisplay-Regular", size: 14))
                    .foregroundColor(Color(hex: "#AC57A7"))
                    .shadow(color: .white.opacity(0.8), radius: 1, x: 0, y: 1)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
