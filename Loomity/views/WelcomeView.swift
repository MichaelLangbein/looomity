//
//  WelcomeView.swift
//  Looomity
//
//  Created by Michael Langbein on 28.12.22.
//

import SwiftUI




struct WelcomeView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State var showTutorial = false
    
    var body: some View {
        NavigationView {
            FullPageView {
                VStack {
                    Image("nobackground")
                        .resizable()
                        .frame(width: 200, height: 200)
                    
                    VStack (alignment: .center, spacing: 9) {
                        Text("Loomity helps you inspect the proportions of faces in your photos.")
                            .multilineTextAlignment(.center)
                    }
                    .textBox()
                    
                    HStack {
                        NavigationLink(destination: SelectImageView()) {
                            Text("Select image")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(purchaseManager.purchaseState == .newUser || purchaseManager.purchaseState == .inTrialOver)

                        Button("Tutorial") {
                            showTutorial = true
                        }.buttonStyle(.borderedProminent)
                        
                        NavigationLink(destination: AboutView()) {
                            Text("About")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        

                    }
                    .padding(EdgeInsets(top: 0, leading: UIScreen.main.bounds.width * 0.075, bottom: 0, trailing: UIScreen.main.bounds.width * 0.075))
                    .fixedSize(horizontal: false, vertical: true)
                    
                    TrialView().environmentObject(purchaseManager)
                }
                .sheet(isPresented: $showTutorial) {
                    TutorialView(show: $showTutorial)
                }
            }
            .navigationBarTitle("Welcome to Loomity!")
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView().environmentObject(PurchaseManager())
    }
}
