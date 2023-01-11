//
//  AnalysisOngoingView.swift
//  Looomity
//
//  Created by Michael Langbein on 15.12.22.
//

import SwiftUI

struct AnalysisOngoingView: View {
    let image: UIImage
    
    var body: some View {
        
        VStack {
            
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(3)
                .padding().padding()
            
            VStack(alignment: .center, spacing: 7.5) {
                Text("Attempting to place Loomis model over faces ...")
                    .foregroundColor(.gray)
                Text("Move the model by hand until it fits perfectly!")
                    .foregroundColor(.gray)

            }
            
            Spacer()
        }
    }
}

struct AnalysisOngoingView_Previews: PreviewProvider {
    static var previews: some View {
        let image = UIImage(named: "TestImage")!
        AnalysisOngoingView(image: image)
    }
}
