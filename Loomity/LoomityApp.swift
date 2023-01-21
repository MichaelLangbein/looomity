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
                .task {
                    await purchaseManager.updatePurchasedProducts()
                }
                .task {
                    do {
                        try await purchaseManager.loadProducts()
                    } catch {
                        print(error)
                    }
                }
        }
    }
}
