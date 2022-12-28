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
                .scaleEffect(4)
                .padding().padding()
            
            Text("Attempting to place Loomis model nicely...")
                .foregroundColor(.gray)
            
            
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
