//
//  LandmarkView.swift
//  Loomity
//
//  Created by Michael Langbein on 31.12.22.
//

import SwiftUI
import Vision


struct LandmarkView: View {
    let image: UIImage
    let observations: [VNFaceObservation]
    
    var body: some View {
        let updatedImage = image.drawLandmarksOnImage(observations: observations)!
        Image(uiImage: updatedImage)
            .resizable()
            .scaledToFit()
            .opacity(0.4)
    }
}

struct Prev: View {

    @State var image: UIImage
    @State private var observations: [VNFaceObservation] = []
    
    var body: some View {
        VStack {
            LandmarkView(image: image, observations: observations)
        }
        .onAppear {
            detectNTimes(n: 1)
        }
    }
    
    func detectNTimes(n: Int) {
        detectFacesWithLandmarks(uiImage: self.image) { obs in
            if n > 0 {
                detectNTimes(n: n - 1)
            } else {
                paint(observations: obs)
            }
        }
    }
    
    func paint(observations: [VNFaceObservation]) {
                    self.observations = observations
                    if let result = self.image.drawLandmarksOnImage(observations: observations) {
                        self.image = result
                    }
    }
}

struct LandmarkView_Previews: PreviewProvider {
    static var previews: some View {
        let img = UIImage(named: "TestImage3")!
        Prev(image: img)
    }
}
