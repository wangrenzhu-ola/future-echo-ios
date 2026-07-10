import Foundation
import StoreKit

protocol PremiumPurchasing: AnyObject {
    func load() async throws -> String?
    func purchase() async throws -> PremiumPurchaseEvent
    func restore() async throws -> Bool
}

enum PremiumPurchaseEvent {
    case purchased
    case pending
    case cancelled
}

@MainActor
final class PremiumStore: ObservableObject {
    enum State: Equatable {
        case loading
        case ready(price: String)
        case purchasing
        case purchased
        case pending
        case cancelled
        case failed(String)
        case unavailable

        var message: String {
            switch self {
            case .loading: return "Checking Future Echo Plus…"
            case .ready(let price): return "Unlock once for \(price)."
            case .purchasing: return "Completing your purchase…"
            case .purchased: return "Future Echo Plus is active."
            case .pending: return "Your purchase is pending approval. The core pause remains available."
            case .cancelled: return "Purchase cancelled. Nothing changed."
            case .failed(let message): return message
            case .unavailable: return "Future Echo Plus is unavailable right now. Try again later."
            }
        }
    }

    static let productID = "com.wangrenzhu.futureecho.plus"

    @Published private(set) var state: State = .loading

    private var client: (any PremiumPurchasing)?

    init(client: (any PremiumPurchasing)? = nil) {
        self.client = client
    }

    func load() async {
        if client == nil {
            guard #available(iOS 15.0, *) else {
                state = .unavailable
                return
            }
            client = StoreKitClient(productID: Self.productID)
        }
        guard let client else {
            state = .unavailable
            return
        }
        do {
            guard let price = try await client.load() else {
                state = .unavailable
                return
            }
            state = .ready(price: price)
        } catch {
            state = .unavailable
        }
    }

    func purchase() async -> Bool {
        guard let client else {
            state = .unavailable
            return false
        }
        state = .purchasing
        do {
            switch try await client.purchase() {
            case .purchased:
                state = .purchased
                return true
            case .pending:
                state = .pending
            case .cancelled:
                state = .cancelled
            }
        } catch {
            state = .failed("Purchase couldn't be completed. Try again.")
        }
        return false
    }

    func restore() async -> Bool {
        guard let client else {
            state = .unavailable
            return false
        }
        do {
            let restored = try await client.restore()
            state = restored ? .purchased : .failed("No previous Future Echo Plus purchase was found.")
            return restored
        } catch {
            state = .failed("Restore couldn't be completed. Try again.")
            return false
        }
    }
}

@available(iOS 15.0, *)
private actor StoreKitClient: PremiumPurchasing {
    private let productID: String
    private var product: Product?

    init(productID: String) {
        self.productID = productID
    }

    func load() async throws -> String? {
        let products = try await Product.products(for: [productID])
        product = products.first
        return product?.displayPrice
    }

    func purchase() async throws -> PremiumPurchaseEvent {
        guard let product else { throw StoreKitError.productUnavailable }
        switch try await product.purchase() {
        case .success(let verification):
            let transaction = try verification.verifiedValue
            await transaction.finish()
            return .purchased
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            throw StoreKitError.unknownResult
        }
    }

    func hasCurrentEntitlement() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID,
               transaction.revocationDate == nil {
                return true
            }
        }
        return false
    }

    func restore() async throws -> Bool {
        try await AppStore.sync()
        return await hasCurrentEntitlement()
    }
}

@available(iOS 15.0, *)
private enum StoreKitError: Error {
    case productUnavailable
    case unknownResult
}

@available(iOS 15.0, *)
private extension VerificationResult {
    var verifiedValue: SignedType {
        get throws {
            switch self {
            case .verified(let value): return value
            case .unverified: throw StoreKitError.unknownResult
            }
        }
    }
}
