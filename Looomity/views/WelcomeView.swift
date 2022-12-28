//
//  WelcomeView.swift
//  Looomity
//
//  Created by Michael Langbein on 28.12.22.
//

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack {
            Image("nobackground")
                .resizable()
                .frame(width: 200, height: 200)
            
            VStack (alignment: .center, spacing: 9) {
                Text("Loomity helps you inspect the proportions of faces in your photos.")
                    .multilineTextAlignment(.center)
            }
            .textBox()
            
            VStack {
                NavigationLink(destination: SelectImageView()) {
                    Text("Select image")
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                
                NavigationLink(destination: AboutView()) {
                    Text("About")
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            
            TrialView()
        }
        .navigationBarTitle("Welcome to Loomity!")
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}