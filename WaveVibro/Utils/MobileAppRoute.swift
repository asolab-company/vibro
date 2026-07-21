import Foundation

enum MobileAppRoute {
    static let queryKey = "wv_app"
    static let queryValue = "ios_4f8d2c7a91b6e3"

    static func paywallURL(_ sourceURL: URL, appUserId: String) -> URL? {
        guard var components = URLComponents(url: sourceURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let parts = components.path.split(separator: "/").map(String.init)
        if parts.first?.lowercased() == "app" {
            components.path = parts.count > 1 ? "/\(parts[1])" : "/"
        }

        let normalizedParts = components.path.split(separator: "/").map(String.init)
        let candidate = normalizedParts.first?.lowercased() ?? "base"
        let slug = candidate.hasPrefix("paywall") ? candidate : "base"
        components.path = slug == "base" ? "/" : "/\(slug)"
        components.queryItems = [
            URLQueryItem(name: "appUserId", value: appUserId),
            URLQueryItem(name: queryKey, value: queryValue),
        ]
        return components.url
    }
}
