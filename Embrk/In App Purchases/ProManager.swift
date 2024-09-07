import SwiftUI
import StoreKit

class ProManager: ObservableObject {
    static let shared = ProManager()
    @Published var isPro = false
    @Published var products: [Product] = []
    
    private init() {
        Task {
            await loadProducts()
            await updateProStatus()
        }
    }
    
    @MainActor
    func loadProducts() async {
        do {
            let products = try await Product.products(for: ["com.yourapp.challenger.pro"])
            self.products = products
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    @MainActor
    func updateProStatus() async {
        guard let proProduct = products.first else {
            isPro = false
            return
        }
        
        if let entitlementResult = await Transaction.currentEntitlement(for: proProduct.id) {
            switch entitlementResult {
            case .verified(let transaction):
                // Check if the product ID matches the one for the pro version
                if transaction.productID == "com.yourapp.challenger.pro" {
                    isPro = true
                    return
                }
            case .unverified(_, _):
                // Handle unverified transaction, possibly set isPro to false
                isPro = false
            }
        }
        
        isPro = false
    }
    
    func purchase() async throws {
        guard let proProduct = products.first else {
            throw StoreError.productNotFound
        }
        
        let result = try await proProduct.purchase()
        
        switch result {
        case .success(let verificationResult):
            switch verificationResult {
            case .verified(_):
                await updateProStatus()
            case .unverified(_, _):
                throw StoreError.verificationFailed
            }
        case .userCancelled:
            throw StoreError.userCancelled
        case .pending:
            throw StoreError.purchasePending
        @unknown default:
            throw StoreError.unknown
        }
    }
    
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateProStatus()
    }
    
    enum StoreError: Error {
        case productNotFound
        case purchaseFailed
        case verificationFailed
        case userCancelled
        case purchasePending
        case unknown
    }
}
