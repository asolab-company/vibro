import SwiftUI

struct Loading: View {
    var onFinish: () -> Void = {}

    @State private var progress: CGFloat = 0
    let barWidth = UIScreen.main.bounds.width * 0.6
    let icWidth = UIScreen.main.bounds.width * 0.7
    var body: some View {
        ZStack {
            GradientBackgroundView()

            VStack {
                Spacer()

                VStack(spacing: 20) {
                    Image("app_bg_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: icWidth)

                    Text("VibroMate")
                        .font(.custom("SFProDisplay-Heavy", size: 28))
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                }

                Spacer()

                VStack(spacing: 8) {
                    Text("\(Int(progress * 100))%")
                        .font(.custom("SFProDisplay-Regular", size: 18))
                        .foregroundColor(.white)

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: barWidth, height: 8)

                        Capsule()
                            .fill(Color.white)
                            .frame(width: barWidth * progress, height: 8)
                            .animation(
                                .easeInOut(duration: 0.2),
                                value: progress
                            )
                    }
                }
                .padding(.bottom, 50)
                .frame(height: 50)
            }
            .padding(.horizontal, 20)

        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) {
                timer in
                if self.progress < 1.0 {
                    self.progress += 0.01
                } else {
                    timer.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onFinish()
                    }
                }
            }
        }
    }
}

#Preview {
    Loading()
}
