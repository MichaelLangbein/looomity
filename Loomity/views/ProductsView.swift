//
//  ProductsView.swift
//  Loomity
//
//  Created by Michael Langbein on 20.01.23.
//

import SwiftUI
import StoreKit



struct ProductView<Content: View>: View {
    let title: String
    let logo: String
    let active: Bool
    @ViewBuilder var content: Content
    private let logoDiameter = UIScreen.main.bounds.width * 0.2
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text(title)
                        .foregroundColor(.accentColor)
                        .font(.title)
        
                    content
                }
                
                Spacer()
                
                Image(logo)
                    .resizable()
                    .frame(width: logoDiameter, height: logoDiameter)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }.frame(maxWidth: .infinity)
        }
        .textBox()
        .saturation(active ? 1.0 : 0.0)
    }
}

struct TrialProductView: View {
    
    let product: Product
    let state: PurchaseState
    let trialDaysRemaining: Int?
    let onBuyTapped: () -> ()
    
    var body: some View {
        ProductView(
            title: product.displayName,
            logo: "TestImage",
            active: state == .newUser || state == .inTrialOngoing
        ) {
            switch state {
            case .newUser:
                VStack (alignment: .leading) {
                    Text("Try it out!")
                    Text("\u{2022} Use Loomity for 7 days without restrictions.")
                    Text("\u{2022} No worries, we don't automatically convert your trial into a subscription.")
                    Button {
                        onBuyTapped()
                    } label: {
                        Text("\(product.displayPrice) - \(product.displayName)")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent)
                }.padding(.leading)
            case .inTrialOngoing:
                VStack (alignment: .leading) {
                    Text("You're in the trial-period.")
                    Text("\(trialDaysRemaining ?? 0) days remaining.")
                }.padding(.leading)
            case .inTrialOver:
                Text("Free trial completed.").padding(.leading)
            default:
                Text("Happy sketching!").padding(.leading)
            }
        }
    }
    


}

struct OneTimeProductView: View {
    
    let product: Product
    let state: PurchaseState
    let onBuyTapped: () -> ()
    
    var body: some View {
        ProductView(title: "One-time purchase", logo: "TestImage2", active: true) {
            switch state {
            case .newUser, .inTrialOngoing, .inTrialOver:
                VStack (alignment: .leading) {
                    Text("Buy now:")
                    Text("\u{2022} Get unlimited use of Loomity.")
                    Text("\u{2022} No subscription: buy it once and it'll always be yours.")
                    Button {
                        onBuyTapped()
                    } label: {
                        Text("\(product.displayPrice) - \(product.displayName)")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent)
                }.padding(.leading)
            case .hasBought:
                Text("Thanks for buying Loomity!").padding(.leading)
            default:
                Text("Happy sketching!").padding(.leading)
            }
        }
    }

}


struct ProductsView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State var purchaseOngoing = false
    
    var body: some View {
        FullPageView {
            ZStack {
                if purchaseManager.productsLoaded {
                    VStack {
                        if let trialProduct = purchaseManager.products[freeTrialID] {
                            TrialProductView(product: trialProduct, state: purchaseManager.purchaseState, trialDaysRemaining: purchaseManager.trialDaysRemaining) {
                                self.purchaseProduct(product: trialProduct)
                            }
                        }
                        if let oneTimeProduct = purchaseManager.products[oneTimePurchaseID] {
                            OneTimeProductView(product: oneTimeProduct, state: purchaseManager.purchaseState) {
                                self.purchaseProduct(product: oneTimeProduct)
                            }
                        }
                        restoreButton
                    }
                    .saturation(self.purchaseOngoing ? 0.0 : 1.0)
                    .opacity(self.purchaseOngoing ? 0.7 : 1.0)
                } else {
                    Text("Loading ...")
                }
                
                if purchaseOngoing {
                    ProgressView()
                }
            }

        }.navigationBarTitle("Products", displayMode: .inline)
    }
    
    func purchaseProduct(product: Product) {
        self.purchaseOngoing = true
        Task {
            do {
                try await self.purchaseManager.purchase(product)
                purchaseOngoing = false
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

}

struct ProductStateView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    var body: some View {
        HStack {
            if purchaseManager.productsLoaded {
                switch purchaseManager.purchaseState {
                case .newUser:
                    Text("Welcome to Loomity!")
                    NavigationLink(destination: ProductsView()) {
                        Text("Start your free trial")
                    }.buttonStyle(.borderedProminent).foregroundColor(.white)
                case .inTrialOngoing:
                    Text("Trial-period: \(purchaseManager.trialDaysRemaining ?? 0) days remaining.")
                    NavigationLink(destination: ProductsView()) {
                        Text("Buy now")
                    }.buttonStyle(.borderedProminent).foregroundColor(.white)
                case .inTrialOver:
                    Text("Your free trial has ended.")
                    NavigationLink(destination: ProductsView()) {
                        Text("Buy now")
                    }.buttonStyle(.borderedProminent).foregroundColor(.white)
                case .hasBought:
                    Text("Thanks for buying Loomity. Happy sketching!")
                default:
                    NavigationLink(destination: ProductsView()) {
                        Text("Products")
                    }.buttonStyle(.borderedProminent).foregroundColor(.white)
                }

            } else {
                Text("Contacting app-store ...")
            }
        }.textBox()
    }
}

struct ProductsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VStack {
                ProductsView()
                ProductStateView()
            }.environmentObject(PurchaseManager())
        }
    }
}
