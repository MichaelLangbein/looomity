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
        
        let ar = image.size.width / image.size.height
        let uiWidth = UIScreen.main.bounds.width
        let w = 0.8 * uiWidth
        let h = w / ar
        
        ZStack {
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .opacity(0.5)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(4)
            
        }.frame(width: w, height: h)
    }
}

struct AnalysisOngoingView_Previews: PreviewProvider {
    static var previews: some View {
        let image = UIImage(named: "TestImage")!
        AnalysisOngoingView(image: image)
    }
}
