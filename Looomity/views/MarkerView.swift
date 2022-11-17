//
//  MarkerView.swift
//  Looomity
//
//  Created by Michael Langbein on 17.11.22.
//  Based on https://www.hackingwithswift.com/quick-start/swiftui/how-to-integrate-spritekit-using-spriteview

import SwiftUI
import Vision


struct MarkerView: View {
    // Parameters for a detected face
    var observation: VNFaceObservation
    // Aspect-ratio of underlying photo
    var imageSize: CGSize
    
    
    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .foregroundColor(.clear)
                .border(.red)
                .offset(
                    x: geo.size.width * observation.boundingBox.minX,
                    y: geo.size.height * (1.0 - observation.boundingBox.maxY)
                ).frame(
                    width: geo.size.width * observation.boundingBox.width,
                    height: geo.size.height * observation.boundingBox.height
                )
        }
    }
}

struct MarkerView_Previews: PreviewProvider {
    static var previews: some View {
        let observation = VNFaceObservation(
            requestRevision: 0,
            boundingBox: CGRect(x: 0.4, y: 0.75, width: 0.125, height: 0.125),
            roll: 0.3,
            yaw: 0.01,
            pitch: -0.3
        )
        
        let img = UIImage(named: "TestImage")
        let size = img!.size
        let ar = size.width / size.height
        let uiWidth = UIScreen.main.bounds.width
        let w = 0.8 * uiWidth
        let h = w / ar
        
        return ZStack {

            Image(uiImage: img!)
                .resizable()
                .scaledToFit()
                .border(.green)
            
            MarkerView(observation: observation, imageSize: size)
                .border(.blue)
            
        }.frame(width: w, height: h)
    }
}
