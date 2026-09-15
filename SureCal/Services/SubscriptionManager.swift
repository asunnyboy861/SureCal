import Foundation
import StoreKit
import Combine

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var isPro: Bool = false
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var loadError: String?

    private let productIDs = [PricingConfig.monthlyID, PricingConfig.yearlyID]
    private var transactionListener: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
        Task { await checkEntitlement() }
    }

    var yearlyProduct: Product? { products.first { $0.id == PricingConfig.yearlyID } }
    var monthlyProduct: Product? { products.first { $0.id == PricingConfig.monthlyID } }
    var hasIntroOffer: Bool {
        yearlyProduct?.subscription?.introductoryOffer != nil || monthlyProduct?.subscription?.introductoryOffer != nil
    }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
            loadError = nil
        } catch {
            loadError = "Unable to load purchase options."
        }
        isLoading = false
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await checkEntitlement()
                    await transaction.finish()
                    return true
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            loadError = "Purchase failed: \(error.localizedDescription)"
        }
        return false
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkEntitlement()
        } catch {
            loadError = "Restore failed: \(error.localizedDescription)"
        }
    }

    func checkEntitlement() async {
        var entitled = false
        for id in productIDs {
            if let result = await Transaction.currentEntitlement(for: id) {
                if case .verified(let transaction) = result, transaction.revocationDate == nil {
                    entitled = true
                }
            }
        }
        isPro = entitled
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    Task { @MainActor [weak self] in
                        await self?.checkEntitlement()
                    }
                }
            }
        }
    }

    deinit {
        transactionListener?.cancel()
    }
}
