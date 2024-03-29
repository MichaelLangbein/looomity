//
//  TrialView.swift
//  Looomity
//
//  Created by Michael Langbein on 28.12.22.
//

import SwiftUI
import StoreKit



struct TrialView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    
    var body: some View {
        VStack {
            if purchaseManager.productsLoaded {
                switch purchaseManager.purchaseState {
                case .newUser:
                    Text("Welcome to Loomity! Get started with a free trial.")
                    if let trialProduct = purchaseManager.products[freeTrialID] {
                        productPurchaseButton(product: trialProduct)
                    }
                    if let purchaseProduct = purchaseManager.products[oneTimePurchaseID] {
                        productPurchaseButton(product: purchaseProduct)
                    }
                    restoreButton
                case .inTrialOngoing, .inTrialOver:
                    Text("You're in the trial-period. \(purchaseManager.trialDaysRemaining ?? 0) days remaining.")
                    if let purchaseProduct = purchaseManager.products[oneTimePurchaseID] {
                        productPurchaseButton(product: purchaseProduct)
                    }
                    restoreButton
                case .hasBought:
                    Text("Happy sketching!")
                case .error:
                    Text("No connection to app-store ... will try to re-connect on next app-start.")
                }
            } else {
                Text("... loading ...")
            }
        }
        .textBox()
        .padding()
        .fixedSize(horizontal: false, vertical: true)
        .task {
            do {
                try await self.purchaseManager.loadProducts()
            } catch {
                print(error)
            }
        }
    }
    
    
    var restoreButton: some View {
        Button {
            Task {
                do {
                    try await AppStore.sync()
                } catch {
                    print(error)
                }
            }
        } label: {
            Text("Restore purchases")
        }
    }
    
    
    func productPurchaseButton(product: Product) -> some View {
        Button {
            Task {
                do {
                    try await self.purchaseManager.purchase(product)
                } catch {
                    print(error)
                }
            }
        } label: {
            Text("\(product.displayPrice) - \(product.displayName)")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
        }.buttonStyle(.borderedProminent)
    }
    
}

struct TrialView_Previews: PreviewProvider {
    static var previews: some View {
        TrialView().environmentObject(PurchaseManager())
    }
}
