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
    @State private var orientation = UIDeviceOrientation.unknown
    
    var body: some View {
        NavigationView {
            FullPageView {
                VStack {
                    
                    // To prevent `navigationViewTitle` to overlap with logo.
                    Spacer(minLength: UIScreen.main.bounds.height * 0.18)
                    
                    Image("logo_alpha")
                        .resizable()
                        .aspectRatio(contentMode: .fit)  // maintains aspect ratio while scaling.
                        .frame(maxWidth: 200, maxHeight: 200)
                    
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
                    
                    
                    if self.orientation == .unknown || self.orientation == .portrait {
                        Spacer()
                    }
                    
//                    TrialView()
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
                }
                .sheet(isPresented: $showTutorial) {
                    TutorialView(show: $showTutorial)
                }
            }
            .onRotate { orientation in
                self.orientation = orientation
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
