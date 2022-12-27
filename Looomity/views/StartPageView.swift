//
//  NavigationView.swift
//  Looomity
//
//  Created by Michael Langbein on 06.11.22.
//

import SwiftUI

struct StartPageView: View {
    
    // AppStorage is a wrapper for UserDefaults.standard
    @AppStorage("displayOnboarding") private var displayOnboarding: Bool = true
    
    
    init() {
        // works globally
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = .white.withAlphaComponent(0.8)
//        navBarAppearance.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance

    }
    
    var body: some View {
        NavigationView {
            VStack {
                SelectImageView()
            }
            .fullScreenCover(isPresented: $displayOnboarding) {
                TutorialView(show: $displayOnboarding)
            }
        }
    }
}

struct StartPageView_Previews: PreviewProvider {
    static var previews: some View {
        StartPageView()
    }
}
