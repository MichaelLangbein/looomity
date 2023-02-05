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
            Text(title)
                .foregroundColor(.accentColor)
                .font(.title)
                .padding(.leading)
            
            HStack (alignment: .top, spacing: 7.5) {
                content
                
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
            logo: "logo_trial_light2",
            active: state == .newUser || state == .inTrialOngoing
        ) {
            switch state {
            case .newUser:
                VStack (alignment: .leading, spacing: 7.5) {
                    Text("\u{2022} Use Loomity for 7 days without restrictions.")
                    Text("\u{2022} No worries, we won't automatically convert your trial into a subscription.")
                    BlinkView {
                        Button {
                            onBuyTapped()
                        } label: {
                            Text("\(product.displayName)")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }

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
        ProductView(
            title: "One-time purchase",
            logo: "logo_full_light4",
            active: state != .hasBought
        ) {
            switch state {
            case .newUser, .inTrialOngoing, .inTrialOver:
                VStack (alignment: .leading, spacing: 7.5) {
                    Text("\u{2022} Get unlimited use of Loomity.")
                    Text("\u{2022} No subscription: buy it once and it'll always be yours.")
                    Button {
                        onBuyTapped()
                    } label: {
                        Text("\(product.displayPrice) - \(product.displayName)")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
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
    @State var orientation: UIDeviceOrientation = UIScreen.main.bounds.width > UIScreen.main.bounds.height ? .landscapeLeft : .portrait
    
    var body: some View {
        FullPageView {
            ZStack {
                if purchaseManager.productsLoaded {
                    
                    if orientation == .faceUp {
                        if UIScreen.main.bounds.width < UIScreen.main.bounds.height {
                            productsVertical
                        } else {
                            productsHorizontal
                        }
                    }
                    else if orientation != .landscapeLeft && orientation != .landscapeRight {
                        productsVertical
                    }
                    else {
                        productsHorizontal
                    }

                    
                } else {
                    Text("Loading ...")
                }
                
            }

        }.navigationBarTitle("Products", displayMode: .inline)
            .onRotate { orientation in
                self.orientation = orientation
            }
    }
    
    
    var productsVertical: some View {
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
    }
    
    var productsHorizontal: some View {
        VStack {
            HStack {
                if let trialProduct = purchaseManager.products[freeTrialID] {
                    TrialProductView(product: trialProduct, state: purchaseManager.purchaseState, trialDaysRemaining: purchaseManager.trialDaysRemaining) {
                        self.purchaseProduct(product: trialProduct)
                    }
                    .frame(maxHeight: .infinity)
                }
                if let oneTimeProduct = purchaseManager.products[oneTimePurchaseID] {
                    OneTimeProductView(product: oneTimeProduct, state: purchaseManager.purchaseState) {
                        self.purchaseProduct(product: oneTimeProduct)
                    }
                    .frame(maxHeight: .infinity)
                }

            }.fixedSize(horizontal: false, vertical: true)
            restoreButton
        }
    }
    
    func purchaseProduct(product: Product) {
        Task {
            do {
                try await self.purchaseManager.purchase(product)
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
                    BlinkView {
                        NavigationLink(destination: ProductsView()) {
                            Text("Start your free trial")
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundColor(.white)
                    }
                    
                case .inTrialOngoing:
                    Text("Trial-period: \(purchaseManager.trialDaysRemaining ?? 0) days remaining.")
                    NavigationLink(destination: ProductsView()) {
                        Text("Buy now")
                    }.buttonStyle(.borderedProminent).foregroundColor(.white)
                case .inTrialOver:
                    Text("Your free trial has ended.")
                    BlinkView {
                        NavigationLink(destination: ProductsView()) {
                            Text("Buy now")
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundColor(.white)
                    }
                    
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
