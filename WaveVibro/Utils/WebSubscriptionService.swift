import Foundation
import UIKit

struct WebSubscriptionServiceStatus: Decodable {
    let active: Bool
    let subscription: WebSubscriptionServiceSubscription?
}

struct WebSubscriptionServiceSubscription: Decodable {
    let customerId: String?
    let subscriptionId: String?
    let status: String?
    let currentPeriodEnd: String?
    let trialEnd: String?
    let cancelAtPeriodEnd: Bool?
}

private struct WebSubscriptionPortalResponse: Decodable {
    let portalUrl: String
}

private struct WebSubscriptionServiceErrorResponse: Decodable {
    let error: String?
}

struct WebSubscriptionCancelResponse: Decodable {
    let active: Bool
    let cancelled: Bool?
    let alreadyCancelled: Bool?
    let subscription: WebSubscriptionServiceSubscription?
}

private struct WebSubscriptionCancelPolicyResponse: Decodable {
    let showCancelButton: Bool
    let countryCode: String?
}

enum WebSubscriptionServiceError: LocalizedError {
    case routeUnavailable
    case invalidServerResponse
    case noPortalUrl
    case serverMessage(String?)

    var errorDescription: String? {
        switch self {
        case .routeUnavailable:
            return "Subscription management is not available right now."
        case .invalidServerResponse:
            return "Could not read the subscription response."
        case .noPortalUrl:
            return "Stripe did not return a portal URL."
        case .serverMessage(let message):
            return message ?? "Subscription could not be cancelled right now."
        }
    }
}

enum WebSubscriptionService {
    private static let webSubscriptionActiveKey = "web_subscription_active"
    private static let webSubscriptionIdKey = "web_subscription_id"

    private static func identityPayload() -> [String: String] {
        var payload = ["appUserId": WebSubscriptionIdentity.appUserId]
        if let subscriptionId = UserDefaults.standard.string(forKey: webSubscriptionIdKey),
           !subscriptionId.isEmpty {
            payload["subscriptionId"] = subscriptionId
        }
        return payload
    }

    private static func decodedRouteURL() -> URL? {
        guard
            let firstData = Data(base64Encoded: RouteData.key),
            let firstString = String(data: firstData, encoding: .utf8),
            let secondData = Data(base64Encoded: firstString),
            let finalString = String(data: secondData, encoding: .utf8)
        else {
            return nil
        }

        return URL(string: finalString)
    }

    private static func resolvePaywallURL() async throws -> URL {
        guard let routeURL = decodedRouteURL() else {
            throw WebSubscriptionServiceError.routeUnavailable
        }

        let (data, _) = try await URLSession.shared.data(from: routeURL)
        guard
            let responseText = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            !responseText.lowercased().contains(RouteData.check),
            let paywallURL = URL(string: responseText)
        else {
            throw WebSubscriptionServiceError.routeUnavailable
        }

        return paywallURL
    }

    private static func apiURL(path: String) async throws -> URL {
        let paywallURL = try await resolvePaywallURL()
        guard var components = URLComponents(url: paywallURL, resolvingAgainstBaseURL: false) else {
            throw WebSubscriptionServiceError.routeUnavailable
        }

        components.path = path
        components.queryItems = nil

        guard let url = components.url else {
            throw WebSubscriptionServiceError.routeUnavailable
        }

        return url
    }

    static func fetchStatus() async throws -> WebSubscriptionServiceStatus {
        let url = try await apiURL(path: "/api/subscription/status")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: identityPayload())

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode)
        else {
            throw WebSubscriptionServiceError.invalidServerResponse
        }

        return try JSONDecoder().decode(WebSubscriptionServiceStatus.self, from: data)
    }

    static func createBillingPortalURL() async throws -> URL {
        let url = try await apiURL(path: "/api/subscription/portal")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: identityPayload())

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode)
        else {
            throw WebSubscriptionServiceError.invalidServerResponse
        }

        let payload = try JSONDecoder().decode(WebSubscriptionPortalResponse.self, from: data)
        guard let portalURL = URL(string: payload.portalUrl) else {
            throw WebSubscriptionServiceError.noPortalUrl
        }

        return portalURL
    }

    static func cancelWebSubscription() async throws -> WebSubscriptionCancelResponse {
        let url = try await apiURL(path: "/api/subscription/cancel")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: identityPayload())

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode)
        else {
            let message = try? JSONDecoder().decode(WebSubscriptionServiceErrorResponse.self, from: data)
            throw WebSubscriptionServiceError.serverMessage(message?.error)
        }

        return try JSONDecoder().decode(WebSubscriptionCancelResponse.self, from: data)
    }

    static func fetchCancelButtonPolicy() async throws -> Bool {
        let url = try await apiURL(path: "/api/subscription/cancel-policy")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: identityPayload())

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode)
        else {
            throw WebSubscriptionServiceError.invalidServerResponse
        }

        return try JSONDecoder().decode(WebSubscriptionCancelPolicyResponse.self, from: data).showCancelButton
    }

    @MainActor
    static func refreshCancelButtonPolicy() async {
        do {
            let visible = try await fetchCancelButtonPolicy()
            IAPManager.shared.setCancelSubscriptionButtonVisible(visible)
        } catch {
        }
    }

    @MainActor
    static func refreshLocalStatusIfNeeded() async {
        await IAPManager.shared.refreshEntitlements()
        guard !IAPManager.shared.hasStoreKitSubscription else {
            return
        }

        let hasLocalWebSubscription =
            IAPManager.shared.isWebSubscriptionActive ||
            UserDefaults.standard.bool(forKey: webSubscriptionActiveKey)
        guard hasLocalWebSubscription else {
            return
        }

        do {
            let status = try await fetchStatus()
            IAPManager.shared.setWebSubscriptionActive(
                status.active,
                customerId: status.subscription?.customerId,
                subscriptionId: status.subscription?.subscriptionId,
                cancelAtPeriodEnd: status.subscription?.cancelAtPeriodEnd ?? false
            )
            // Cancel Subscription is disabled for the current app release.
            // Re-enable together with the Settings button:
            // await refreshCancelButtonPolicy()
        } catch {
        }
    }
}
