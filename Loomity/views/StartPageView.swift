//
//  NavigationView.swift
//  Looomity
//
//  Created by Michael Langbein on 06.11.22.
//

import SwiftUI

struct StartPageView: View {
    
    
    init() {
        // applies globally
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = .white.withAlphaComponent(0.8)
//        navBarAppearance.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(.accentColor)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(.accentColor).withAlphaComponent(0.2)

    }
    
    var body: some View {
        NavigationView {
            VStack {
                WelcomeView()
            }
        }
    }
}

struct StartPageView_Previews: PreviewProvider {
    static var previews: some View {
        StartPageView()
    }
}
