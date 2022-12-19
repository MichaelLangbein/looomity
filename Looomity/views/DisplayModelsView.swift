//
//  ContentView.swift
//  Looomity
//
//  Created by Michael Langbein on 05.11.22.
//

import SwiftUI
import Vision
import SceneKit


/**
 *  Container for
 *   - UI-elements
 *   - 2D effects applied on top of SceneKit
 */
struct DisplayModelsView: View {
    let image: UIImage
    let observations: [VNFaceObservation]
    
    @State var opacity = 1.0
    @State var imageTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)
    
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
//                    .scaleEffect(imageScaledBy)
                    .transformEffect(imageTransform)
                
                HeadView(observations: observations, imageSize: image.size,
                         onImagePinch: onScale, onImagePan: onPan)
                    .frame(width: w, height: h)
                    .border(.red)
                    .opacity(opacity)

            }.frame(width: w, height: h)
            
            Slider(value: $opacity, in: 0.0 ... 1.0 )
            Text("Opacity: \(Int(opacity * 100))%")
        
            Spacer()

        }.navigationBarTitle("Analysis")
    }
    
    func onScale(view: SCNView, gesture: UIPinchGestureRecognizer) {
        imageTransform.a = gesture.scale
        imageTransform.d = gesture.scale
        imageTransform.tx = image.size.width  * (1.0 - gesture.scale) / 2.0
        imageTransform.ty = image.size.height * (1.0 - gesture.scale) / 2.0
    }
    
    func onPan(view: SCNView, gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        imageTransform.tx = translation.x
        imageTransform.ty = translation.y
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
