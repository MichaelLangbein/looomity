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
    
    var body: some View {
        NavigationView {
            VStack {
                SelectImageView()
            }
            .fullScreenCover(isPresented: $displayOnboarding) {
                TutorialView(show: $displayOnboarding)
            }
            .navigationTitle("Loomity")
            
        }
    }
}

struct StartPageView_Previews: PreviewProvider {
    static var previews: some View {
        StartPageView()
    }
}
