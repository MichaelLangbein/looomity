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
                    
                    // To prevent `navigationViewTitle` to overlap with logo.
                     Spacer(minLength: UIScreen.main.bounds.height * 0.18)
                    
                    if UIScreen.main.bounds.width <= UIScreen.main.bounds.height {
                        ZStack {
                            Rectangle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(.systemBackground), .accentColor
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .frame(maxWidth: 200, maxHeight: 200)
                                .cornerRadius(30)
                                .shadow(radius: 5)
                            
                            Image("logo_alpha2")
                                .resizable()
                                .aspectRatio(contentMode: .fit)  // maintains aspect ratio while scaling.
                                .frame(maxWidth: 200, maxHeight: 200)
                                .padding(.trailing)
                        }
                    }

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

                        Button {
                            showTutorial = true
                        } label: {
                            Text("Tutorial")
                                .frame(maxWidth: .infinity)
                        }.buttonStyle(.borderedProminent)
                    
                    }
                    .padding(.leading)
                    .padding(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
                    
                    if UIScreen.main.bounds.width <= UIScreen.main.bounds.height {
                        Spacer()
                    }
                    
                    ProductStateView()
                    
                    HStack {
                        Spacer()
                        NavigationLink(destination: AboutView()) {
                            Text("About")
                        }
                        Spacer()
                        NavigationLink(destination: PrivacyView()) {
                            Text("Privacy")
                        }
                        Spacer()
                    }
                    .padding()
                    .padding(.bottom)
                    .padding(.bottom)
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
