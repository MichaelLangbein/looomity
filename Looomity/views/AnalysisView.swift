//
//  AnalysisWrapper.swift
//  Looomity
//
//  Created by Michael Langbein on 15.12.22.
//

import SwiftUI
import Vision


enum AnalysisState {
    case ongoing, done
}

struct AnalysisView: View {
    
    let image: UIImage
    @State var currentState: AnalysisState = .ongoing
    @State var observations: [VNFaceObservation] = []
    @State var showHelp = false
    
    var body: some View {
        VStack {
            if currentState == .ongoing {
                AnalysisOngoingView(image: image)
            } else {
                DisplayModelsView(image: image, observations: observations)
            }
        }
        .onAppear {
            detectFace(uiImage: image) { obs in
                observations = obs
                currentState = .done
            }
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .toolbar {
            Button {
                showHelp = true
            } label: {
                Label("Help", systemImage: "questionmark.circle")
            }
        }
        .navigationTitle("Loomity")
    }
}

struct AnalysisWrapper_Previews: PreviewProvider {
    static var previews: some View {
        let img = UIImage(named: "TestImage2")!
        AnalysisView(image: img)
    }
}
