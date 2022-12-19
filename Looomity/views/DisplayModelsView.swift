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
    
    @State var opacity = 1.0
    @State var imageScaledBy = 1.0
    
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
                    .scaleEffect(imageScaledBy)
                
//                MarkerView(observations: observations, imageSize: image.size)
//                    .frame(width: w, height: h)
//                    .border(.blue)
                
                HeadView(observations: observations, imageSize: image.size, onImagePinch: onScale)
                    .frame(width: w, height: h)
                    .border(.red)
                    .opacity(opacity)

            }.frame(width: w, height: h)
            
            Slider(value: $opacity, in: 0.0 ... 1.0 )
            Text("Opacity: \(Int(opacity * 100))%")
        
            Spacer()

        }.navigationBarTitle("Analysis")
    }
    
    func onScale(gesture: UIPinchGestureRecognizer) {
        imageScaledBy = gesture.scale
    }

}


struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {

        let img = UIImage(named: "TestImage2")!
        
        let observation1 = VNFaceObservation(
            requestRevision: 0,
            boundingBox: CGRect(x: 0.545, y: 0.276, width: 0.439, height: 0.436),
            roll: 0.138,
            yaw: -0.482,
            pitch: 0.112
        )
        
        let observation2 = VNFaceObservation(
            requestRevision: 0,
            boundingBox: CGRect(x: 0.218, y: 0.248, width: 0.382, height: 0.379),
            roll: -0.216,
            yaw: 0.121,
            pitch: 0.151
        )
        
        DisplayModelsView(image: img, observations: [observation1, observation2])
    }
}
