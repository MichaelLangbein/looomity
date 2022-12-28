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
            
//            Image(uiImage: image)
//                .resizable()
//                .scaledToFit()
//                .opacity(0.5)

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(4)
            
        }
    }
}

struct AnalysisOngoingView_Previews: PreviewProvider {
    static var previews: some View {
        let image = UIImage(named: "TestImage")!
        AnalysisOngoingView(image: image)
    }
}
