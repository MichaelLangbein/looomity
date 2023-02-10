//
//  PurchaseManager.swift
//  Loomity
//
//  Created by Michael Langbein on 05.01.23.
//  based on https://www.revenuecat.com/blog/engineering/ios-in-app-subscription-tutorial-with-storekit-2-and-swift/
//  with feedback from https://developer.apple.com/forums/thread/722874
//
//  Active Customer: First check should be to see if purchased the 1-time purchase non-consumable, if so, then grant access. If not go to -> #2
//  Active Trial Customers: now check if they bought Free Trial non-consumable. If so, check if that trial is active or not. If active grant access, if not go to ->#3
//  Inactive Trial Customer: They bought the trial but that trial period has ended, so you then merchandise your paid 1-time purchase non-consumable. But if no transaction is found, go to -> #4
//  New Customers: this is when no IAP was found to be purchased, therefore they are “new” and you should merchandise the Free Trial non-consumable.
//

import StoreKit

let freeTrialID = "net.codeandcolors.loomity.LoomityFreeTrial"
let oneTimePurchaseID = "net.codeandcolors.loomity.LoomityOneTimePurchase"

enum PurchaseState {
    case newUser, inTrialOngoing, inTrialOver, hasBought, error
}

@MainActor class PurchaseManager: NSObject, ObservableObject {
    
    @Published private(set) var productsLoaded = false
    @Published private(set) var completedTransactions: [String: Transaction] = [:]
    @Published private(set) var products: [String: Product] = [:]
    private var updates: Task<Void, Never>?
    
    public var purchaseState: PurchaseState {
        if self.products.count == 0 {
            return .error
        }
        if self.completedTransactions.keys.contains(oneTimePurchaseID) {
            return .hasBought
        }
        if self.completedTransactions.keys.contains(freeTrialID) {
            guard let trialEnd = self.trialEndDate else { return .error }
            let today = Date()
            if today > trialEnd {
                return .inTrialOver
            } else {
                return .inTrialOngoing
            }
        }
        return .newUser
    }
    
    public var mayUse: Bool {
        return self.purchaseState == .hasBought || self.purchaseState == .inTrialOngoing
    }
    
    public var trialDaysRemaining: Int? {
        if self.purchaseState == .inTrialOngoing {
            guard let trialEnd = self.trialEndDate else { return nil }
            let today = Date()
//             let daysLeft = Calendar.current.dateComponents([.day, .hour, .minute], from: today, to: trialEnd) // <-- doesn't get negative
            let secondsLeft = trialEnd.timeIntervalSince(today)
            if secondsLeft <= 0.0 {
                return 0
            }
            let daysLeft = Int(ceil(secondsLeft / (24 * 60 * 60)))
            return daysLeft
        }
        if self.purchaseState == .inTrialOver {
            return 0
        }
        return nil
    }
    
    public var trialEndDate: Date? {
        guard let trialProductTransaction = self.completedTransactions[freeTrialID] else { return nil }
        let trialStartDate = trialProductTransaction.purchaseDate
        let trialEndDate = trialStartDate + TimeInterval(7 * 24 * 60 * 60)
        return trialEndDate
    }
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        self.updates = observeTransactionUpdates()
    }
    
    deinit {
        self.updates?.cancel()
    }
    
    func loadProducts() async throws {
        if self.productsLoaded { return }
        let products = try await Product.products(for: [freeTrialID, oneTimePurchaseID])
        for product in products {
            self.products[product.id] = product
        }
        self.productsLoaded = true
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case let .success(.verified(transaction)):
            await transaction.finish()
            await self.updatePurchasedProducts()
        case let .success(.unverified(_, error)):
            // successful purchase but transaction/receipt can't be verified
            // could be a jailbroken phone
            print(error)
            break
        case .pending:
            // transaction waiting on SCA (strong customer authentication)
            // or approval from Ask to Buy
            break
        case .userCancelled:
            // no need to handle this
            break
        @unknown default:
            break
        }
    }
    
    // `updatePurchasedProducts` needs to be called
    // on application start, after a purchase is made,
    // and when transactions are updated
    // to ensure that `purchasedProductIDs (and `hasMadeAnyPurchase`)
    // are up-to-date
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {  // will return locally cached data if offline
            guard case .verified(let transaction) = result else {
                continue  // not a verified transaction, so just move on to next one
            }

            if transaction.revocationDate == nil {
                self.completedTransactions[transaction.productID] = transaction
            } else {
                self.completedTransactions.removeValue(forKey: transaction.productID) // removes key as well
            }
        }
        print("Updated products: \(self.completedTransactions.keys)")
    }
    
    // listening for new transactions created outside the app.
    // these could be subscriptions that were cancelled, renewed,
    // or revoked due to billing issues, or new purchases
    // made from another device
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await _ in Transaction.updates {
                // using verificationResult directly would be better
                // but this way works for this tutorial
                await self.updatePurchasedProducts()
            }
        }
    }
    
}


// StoreKit 1 stuff.
// This is to handle users being directed to the app
// directly from an AppStore when clicking an IAP.
extension PurchaseManager: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return true
    }
    
}
