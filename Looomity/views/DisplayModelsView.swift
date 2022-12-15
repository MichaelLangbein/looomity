//
//  ContentView.swift
//  Looomity
//
//  Created by Michael Langbein on 05.11.22.
//

import SwiftUI
import Vision



struct DisplayModelsView: View {
    let image: UIImage
    let observations: [VNFaceObservation]
    
    var body: some View {
        VStack (alignment: .center) {
            
            Spacer()
            
            let ar = image.size.height / image.size.width
            let w = UIScreen.main.bounds.width * 0.9
            let h = ar * w
            
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .border(.green)
                
                MarkerView(observations: observations, imageSize: image.size)
                    .frame(width: w, height: h)
                    .border(.blue)
                
                HeadView(observations: observations, imageSize: image.size)
                    .frame(width: w, height: h)
                    .border(.red)
                
            }.frame(width: w, height: h)
        
            Spacer()

        }.navigationBarTitle("Analysis")
    }

}


struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        let img = UIImage(named: "TestImage")!
        DisplayModelsView(image: img, observations: [])
    }
}
