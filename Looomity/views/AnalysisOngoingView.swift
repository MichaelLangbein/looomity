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
        ZStack {
            Spacer()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .opacity(0.5)
            
            ProgressView().progressViewStyle(CircularProgressViewStyle())
            
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
