import Foundation
import StoreKit

private let webSubscriptionActiveKey = "web_subscription_active"
private let webSubscriptionCustomerIdKey = "web_subscription_customer_id"
private let webSubscriptionIdKey = "web_subscription_id"
private let webSubscriptionCancelAtPeriodEndKey = "web_subscription_cancel_at_period_end"
private let cancelSubscriptionButtonVisibleKey = "cancel_subscription_button_visible"

@MainActor
final class IAPManager: NSObject, ObservableObject {
    static let shared = IAPManager()

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isSubscribed: Bool = false
    @Published var hasStoreKitSubscription: Bool = false
    @Published var isWebSubscriptionActive: Bool = false
    @Published var isWebSubscriptionCancelAtPeriodEnd: Bool = false
    @Published var canShowCancelSubscriptionButton: Bool = true
    @Published var isLoadingProducts: Bool = false

    private let productIDs: Set<String> = [Constants.weekly, Constants.yearly]

    private override init() {
        super.init()
        Task {
            observeTransactionUpdates()
            await fetchProducts()
            await refreshEntitlements()
        }
    }

    func setWebSubscriptionActive(
        _ active: Bool,
        customerId: String? = nil,
        subscriptionId: String? = nil,
        cancelAtPeriodEnd: Bool = false
    ) {
        UserDefaults.standard.set(active, forKey: webSubscriptionActiveKey)
        UserDefaults.standard.set(active ? cancelAtPeriodEnd : false, forKey: webSubscriptionCancelAtPeriodEndKey)
        if let customerId, !customerId.isEmpty {
            UserDefaults.standard.set(customerId, forKey: webSubscriptionCustomerIdKey)
        }
        if let subscriptionId, !subscriptionId.isEmpty {
            UserDefaults.standard.set(subscriptionId, forKey: webSubscriptionIdKey)
        }
        Task { await refreshEntitlements() }
    }

    func setCancelSubscriptionButtonVisible(_ visible: Bool) {
        UserDefaults.standard.set(visible, forKey: cancelSubscriptionButtonVisibleKey)
        canShowCancelSubscriptionButton = visible
    }

 
    func fetchProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: Array(productIDs))
            products = loaded.sorted { $0.price < $1.price }
        } catch {
        }
    }


    func purchase(id: String) async {
        guard let product = products.first(where: { $0.id == id }) else { return }
        await purchase(product: product)
    }

    func purchase(product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let tx):
                    await tx.finish()
                    await refreshEntitlements()
                case .unverified(_, let error):
                    _ = error
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
        }
    }


    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
        }
    }

 
    func refreshEntitlements() async {
        var owned = Set<String>()
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let tx) = entitlement {
                owned.insert(tx.productID)
            }
        }
        purchasedProductIDs = owned
        let storeKitActive = await computeActiveSubscription()
        let webActive = UserDefaults.standard.bool(forKey: webSubscriptionActiveKey)
        let webCancelAtPeriodEnd = webActive
            ? UserDefaults.standard.bool(forKey: webSubscriptionCancelAtPeriodEndKey)
            : false
        let cancelButtonVisible = UserDefaults.standard.object(forKey: cancelSubscriptionButtonVisibleKey) as? Bool ?? true
        hasStoreKitSubscription = storeKitActive
        isWebSubscriptionActive = webActive
        isWebSubscriptionCancelAtPeriodEnd = webCancelAtPeriodEnd
        canShowCancelSubscriptionButton = cancelButtonVisible
        isSubscribed = storeKitActive || webActive
    }

    private func computeActiveSubscription() async -> Bool {
        for id in productIDs {
            if let latest = await Transaction.latest(for: id),
               case .verified(let tx) = latest,
               tx.revocationDate == nil,
               (tx.expirationDate ?? .distantFuture) > Date() {
                return true
            }
        }
        return false
    }

 
    func observeTransactionUpdates() {
        Task.detached { [weak self] in
            guard let self else { return }
            for await update in Transaction.updates {
                if case .verified(let tx) = update {
                    await tx.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }
}
