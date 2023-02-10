//
//  LoomityApp.swift
//  Loomity
//
//  Created by Michael Langbein on 28.12.22.
//

import SwiftUI

@main
struct LoomityApp: App {
    @StateObject private var purchaseManager = PurchaseManager()
    @State var hasErrorMessage = false
    @State var errorMessage: String? = nil
    
    init() {
        // applies globally
        
        // Nav-bar
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = .systemBackground.withAlphaComponent(0.8)
//        navBarAppearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // Little points in tutorial view
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(.accentColor)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(.accentColor).withAlphaComponent(0.2)
    }
    
    var body: some Scene {
        WindowGroup {
            WelcomeView()
                .environmentObject(purchaseManager)
                .alert(
                    "Something went wrong",
                    isPresented: $hasErrorMessage,
                    actions: {
                        Button("OK") {
                            hasErrorMessage = false
                            errorMessage = nil
                        }
                    },
                    message: {Text(self.errorMessage ?? "Unknown error on loading products.")}
                )
                .task {
                    await purchaseManager.updatePurchasedProducts()
                }
                .task {
                    do {
                        try await purchaseManager.loadProducts()
                    } catch {
                        hasErrorMessage = true
                        errorMessage = error.localizedDescription
                    }
                }
        }
    }
}
