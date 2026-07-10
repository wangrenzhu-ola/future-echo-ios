import Foundation
import StoreKit

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

    private var client: Any?

    func load() async {
        guard #available(iOS 15.0, *) else {
            state = .unavailable
            return
        }
        let storeKitClient = StoreKitClient(productID: Self.productID)
        client = storeKitClient
        do {
            guard let price = try await storeKitClient.load() else {
                state = .unavailable
                return
            }
            state = .ready(price: price)
        } catch {
            state = .unavailable
        }
    }

    func purchase() async -> Bool {
        guard #available(iOS 15.0, *), let client = client as? StoreKitClient else {
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
        guard #available(iOS 15.0, *), let client = client as? StoreKitClient else {
            state = .unavailable
            return false
        }
        do {
            try await AppStore.sync()
            let restored = await client.hasCurrentEntitlement()
            state = restored ? .purchased : .failed("No previous Future Echo Plus purchase was found.")
            return restored
        } catch {
            state = .failed("Restore couldn't be completed. Try again.")
            return false
        }
    }
}

@available(iOS 15.0, *)
private actor StoreKitClient {
    enum PurchaseEvent {
        case purchased
        case pending
        case cancelled
    }

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

    func purchase() async throws -> PurchaseEvent {
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
