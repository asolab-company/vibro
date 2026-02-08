import SwiftUI
import StoreKit
import ApphudSDK

enum PlanType {
    case weekly, yearly
}

struct PayWall: View {
    @EnvironmentObject var iap: IAPManager

    @State private var currentTab = 0

    @State private var selectedPlan: PlanType = .weekly


    @State private var didTrackShownOnce = false
    @State private var lastTrackedPlan: PlanType = .weekly


    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack(alignment: .top) {

                Color(hex: "FFF9FD").ignoresSafeArea()
                Image("paywall_top")
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()

                Text("Unlimited Access")
                    .font(
                        .custom(
                            "SFProDisplay-Heavy",
                            size: width * 0.07,
                            relativeTo: .title
                        )
                    )
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .dynamicTypeSize(.medium ... .xxLarge)
                    .frame(maxWidth: .infinity)
                    .padding(.top, height * 0.05)

                VStack {
                    VStack(spacing: 20) {

                        HStack {
                            Button {
                                trackTap("pw_close_tap", plan: selectedPlan)
                                dismiss()
                            } label: {
                                Image("ic_close")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 35, height: 35)
                                    .foregroundColor(.white)
                            }

                            Spacer()
                        }

                        Spacer()

                        VStack(alignment: .leading, spacing: height * 0.02) {
                            InfoRow(
                                icon: "ic_check",
                                iconColor: Color(hex: "#A75AAC"),
                                title: "Unlock all vibration modes",
                                description:
                                    "Experience over 20 unique massage modes"
                            )

                            InfoRow(
                                icon: "ic_check",
                                iconColor: Color(hex: "#A75AAC"),
                                title: "Unlock all vibration intensity levels",
                                description:
                                    "Customize the intensity to your preference"
                            )

                            InfoRow(
                                icon: "ic_check",
                                iconColor: Color(hex: "#A75AAC"),
                                title: "Unlock all vibration speeds",
                                description:
                                    "Control the pace from gentle to intense"
                            )
                        }
                        .padding(.horizontal)
                        .padding(.vertical, width * 0.03)
                        .padding(.bottom, height * 0.015)
                        .background(Color(hex: "#FFFFFF").opacity(0.6))
                        .cornerRadius(24)
                        .frame(maxWidth: .infinity)


                        PlanCard(
                            title: weeklyTitle(),
                            subtitle: weeklySubtitle(),
                            badgeText: weeklyBadge(),
                            isSelected: selectedPlan == .weekly,
                            planType: .weekly
                        ) {
                            selectedPlan = .weekly
                            trackTap("pw_plan_card_tap", plan: .weekly)
                            trackPlanChangeIfNeeded(source: "card")
                        }

                        PlanCard(
                            title: "Yearly Access",
                            subtitle: yearlySubtitle(),
                            badgeText: "BEST OFFER",
                            isSelected: selectedPlan == .yearly,

                            planType: .yearly
                        ) {
                            selectedPlan = .yearly
                            trackTap("pw_plan_card_tap", plan: .yearly)
                            trackPlanChangeIfNeeded(source: "card")
                        }

                    }
                    .padding(.horizontal, width * 0.08)
                    .padding(.bottom, height * 0.015)

                    Button(action: {
                        trackTap("pw_continue_tap", plan: selectedPlan)
                        guard let product = iap.products.first(where: {
                            $0.id == (selectedPlan == .weekly ? Constants.weekly : Constants.yearly)
                        }) else {
                            trackTap("pw_continue_no_product", plan: selectedPlan)
                            return
                        }
                        Task {
                            do {
                                trackTap("pw_checkout_initiated", plan: selectedPlan)
                                let result = try await product.purchase()
                                switch result {
                                case .success(let verification):
                                    switch verification {
                                    case .verified(let tx):
                                        trackTap("pw_purchase_success", plan: selectedPlan)
                                        await tx.finish()
                                        await iap.refreshEntitlements()
                                        
                                        dismiss()
                                    case .unverified(_, let error):
                                        trackTap("pw_purchase_unverified", plan: selectedPlan)
                                        print("⚠️ Unverified transaction:", error)
                                        
                                    }
                                case .userCancelled:
                                    trackTap("pw_purchase_cancelled", plan: selectedPlan)
                                    print("❌ Покупка отменена пользователем")
                                    
                                case .pending:
                                    trackTap("pw_purchase_pending", plan: selectedPlan)
                                    print("⏳ Покупка в ожидании")
                                    
                                @unknown default:
                                    trackTap("pw_purchase_unknown", plan: selectedPlan)
                                    break
                                }
                            } catch {
                                trackTap("pw_purchase_error", plan: selectedPlan, extra: error.localizedDescription)
                                print("❌ Ошибка покупки:", error.localizedDescription)
                                
                            }
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

                    VStack(spacing: 20) {

                        HStack(spacing: 8) {
                            Image("ic_shield")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)

                            Text("Cancel Anytime")
                                .font(.custom("SFProDisplay-Bold", size: 13))
                                .foregroundColor(Color(hex: "#AC57A7"))
                        }

                        HStack(spacing: 40) {
                            Button(action: {
                                trackTap("pw_privacy_tap")
                                UIApplication.shared.open(Constants.privacyURL)
                            }) {
                                Text("Privacy Policy")
                                    .font(
                                        .custom(
                                            "SFProDisplay-Regular",
                                            size: 14
                                        )
                                    )
                                    .foregroundColor(Color(hex: "#BDBDBD"))
                            }

                            Button(action: {
                                trackTap("pw_restore_tap", plan: selectedPlan)
                                Task {
                                    await iap.restore()
                                    await iap.refreshEntitlements()
                                    trackTap(iap.isSubscribed ? "pw_restore_success" : "pw_restore_no_active")
                                }
                            }) {
                                Text("Restore")
                                    .font(
                                        .custom(
                                            "SFProDisplay-Regular",
                                            size: 14
                                        )
                                    )
                                    .foregroundColor(Color(hex: "#BDBDBD"))
                            }

                            Button(action: {
                                trackTap("pw_terms_tap")
                                UIApplication.shared.open(Constants.termsURL)
                            }) {
                                Text("Terms of Use")
                                    .font(
                                        .custom(
                                            "SFProDisplay-Regular",
                                            size: 14
                                        )
                                    )
                                    .foregroundColor(Color(hex: "#BDBDBD"))
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }

            }
            .onAppear {
                trackShownIfNeeded()
                
                trackTap("pw_default_plan", plan: selectedPlan)
            }

        }

    }
    

    
    private func planKey(_ plan: PlanType) -> String {
        plan == .weekly ? "weekly" : "yearly"
    }

    private func trackTap(_ name: String, plan: PlanType? = nil, extra: String? = nil) {
        
        
        let base = plan.map { "\(name)_\(planKey($0))" } ?? name
        Apphud.incrementUserProperty(key: .init("\(base)_count"), by: 1)
        Apphud.setUserProperty(key: .init("\(base)_last_ts"), value: Int(Date().timeIntervalSince1970))
        if let extra {
            Apphud.setUserProperty(key: .init("\(base)_last_extra"), value: extra)
        }
    }

    private func trackShownIfNeeded() {
        guard !didTrackShownOnce else { return }
        didTrackShownOnce = true
        lastTrackedPlan = selectedPlan
        trackTap("pw_shown", plan: selectedPlan)
    }

    private func trackPlanChangeIfNeeded(source: String) {
        guard lastTrackedPlan != selectedPlan else { return }
        lastTrackedPlan = selectedPlan
        trackTap("pw_plan_selected", plan: selectedPlan, extra: source)
    }

    
    private func weeklyProduct() -> Product? {
        iap.products.first { $0.id == Constants.weekly }
    }

    private func yearlyProduct() -> Product? {
        iap.products.first { $0.id == Constants.yearly }
    }

    private func weeklyTitle() -> String {
        return "Weekly Access"
    }

    private func weeklySubtitle() -> String {
        guard let product = weeklyProduct() else { return "$4.99 / week" }
        return "\(product.displayPrice) / week"
    }

    private func weeklyBadge() -> String {
        return "POPULAR"
    }

    private func yearlySubtitle() -> String {
        guard let product = yearlyProduct() else { return "$44.99 / year" }
        return "\(product.displayPrice) / year"
    }

    private func continueButtonTitle() -> String {
        guard let product = (selectedPlan == .weekly ? weeklyProduct() : yearlyProduct())
        else { return "Continue" }
        if let offer = product.subscription?.introductoryOffer,
           offer.type == .introductory, offer.price == 0 {
            return "Continue"
        }
        return "Continue – \(product.displayPrice)"
    }

    private func bottomHint() -> String {
        if let product = (selectedPlan == .weekly ? weeklyProduct() : yearlyProduct()),
           let offer = product.subscription?.introductoryOffer,
           offer.type == .introductory, offer.price == 0 {
            return "No Payment Now"
        }
        return "Cancel Anytime"
    }

    private func introBadge(from period: Product.SubscriptionPeriod) -> String? {
        switch period.unit {
        case .day:   return "\(period.value) DAYS FREE"
        case .week:  return "\(period.value) WEEKS FREE"
        case .month: return "\(period.value) MONTHS FREE"
        case .year:  return "\(period.value) YEARS FREE"
        @unknown default: return "FREE TRIAL"
        }
    }
    
    
}

struct PlanCard: View {
    let title: String
    let subtitle: String
    let badgeText: String
    let isSelected: Bool
    let planType: PlanType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.custom("SFProDisplay-Medium", size: 15))
                        .foregroundColor(.black)

                    Text(subtitle)
                        .font(.custom("SFProDisplay-Regular", size: 12))
                        .foregroundColor(.black)
                }

                Spacer()

                if planType == .weekly {
                    Text(badgeText)
                        .font(.custom("SFProDisplay-Medium", size: 11))
                        .fontWeight(.bold)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.white)
                        )
                        .foregroundColor(Color.init(hex: "D0437D"))
                } else {

                    Text(badgeText)
                        .font(.custom("SFProDisplay-Medium", size: 11))
                        .fontWeight(.bold)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "#A75AAC"),
                                            Color(hex: "#D0437D"),
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .foregroundColor(.white)

                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 50)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#A75AAC"), Color(hex: "#D0437D"),
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ).opacity(0.22)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 50)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#A75AAC"),
                                        Color(hex: "#D0437D"),
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: isSelected ? 3.5 : 1.5
                            )
                    )
            )
        }
    }
}


#Preview {
    PayWall()
        .environmentObject(IAPManager.shared)
}
