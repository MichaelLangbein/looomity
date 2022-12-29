//
//  MarkerView.swift
//  Loomity
//
//  Created by Michael Langbein on 29.12.22.
//

import SwiftUI
import Vision


struct MyRect: View {
    
    var color: Color
    var offsetX: CGFloat
    var offsetY: CGFloat
    var width: CGFloat
    var height: CGFloat
    
    var body: some View {
        Rectangle()
            .foregroundColor(self.color)
            .opacity(0.5)
            .border(self.color)
            .offset(
                x: self.offsetX,
                y: self.offsetY
            ).frame(
                width: self.width,
                height: self.height
            )
    }
}

struct MarkerView: View {
    
    var observations: [VNFaceObservation]
    var image: UIImage
    
    var body: some View {
        GeometryReader { geo in
           ForEach(observations, id: \.uuid) { observation in
               
               
               let arImg = image.size.width / image.size.height
               let arUI  = geo.size.width   / geo.size.height
               
               let wUI = geo.size.width
               let hUI = geo.size.height
               let wImg = image.size.width
               let hImg = image.size.height
               let alpha = wUI / wImg // pixels UI per pixel image
               let hImgUI = hImg * alpha
               let hMinUI = (hUI - hImgUI) / 2.0
               
               
               let obsOffsetX =                 observation.boundingBox.minX  * wImg * alpha
               let obsOffsetY = hMinUI + (1.0 - observation.boundingBox.maxY) * hImg * alpha
               let obsWidth   = observation.boundingBox.width  * wImg * alpha
               let obsHeight  = observation.boundingBox.height * hImg * alpha

               MyRect(
                color: .gray,
                offsetX: obsOffsetX,
                offsetY: obsOffsetY,
                width: obsWidth,
                height: obsHeight
               )
               

               ForEach(0 ..< observation.landmarks!.nose!.normalizedPoints.count) { i in
                   let point = observation.landmarks!.nose!.normalizedPoints[i]
                      let pointProjected = VNImagePointForFaceLandmarkPoint(
                        vector_float2(x: Float(point.x), y: Float(point.y)),
                        observation.boundingBox,
                        Int(wImg), Int(hImg)
                      )
                      let pointProjectedNorm = CGPoint(x: pointProjected.x / wImg, y: pointProjected.y / hImg)
                      let pointOffsetX =                 pointProjectedNorm.x  * wImg * alpha
                      let pointOffsetY = hMinUI + (1.0 - pointProjectedNorm.y) * hImg * alpha

                      MyRect(
                       color: .yellow,
                       offsetX: pointOffsetX,
                       offsetY: pointOffsetY,
                       width: 5,
                       height: 5
                      )
               }
               ForEach(0 ..< observation.landmarks!.nose!.normalizedPoints.count) { i in
                   let pt = observation.landmarks!.nose!.normalizedPoints[i]
                   
                   let offsetBboxXImg = observation.boundingBox.minX * wImg
                   let offsetBboxYImg = observation.boundingBox.minY * hImg
                   let wBboxImg       = observation.boundingBox.width * wImg
                   let hBboxImg       = observation.boundingBox.height * hImg
                   let xImg = offsetBboxXImg +  pt.x * observation.boundingBox.width * wImg
                   let yImg = offsetBboxYImg +  pt.y * observation.boundingBox.height * hImg
                   
                   let xUI =                   xImg  * alpha
                   let yUI = hMinUI +  (hImg - yImg) * alpha
                   
                      MyRect(
                       color: .blue,
                       offsetX: xUI,
                       offsetY: yUI,
                       width: 5,
                       height: 5
                      )
               }
               ForEach(0 ..< observation.landmarks!.leftEye!.normalizedPoints.count) { i in
                   let pt = observation.landmarks!.leftEye!.normalizedPoints[i]
                   
                   let offsetBboxXImg = observation.boundingBox.minX * wImg
                   let offsetBboxYImg = observation.boundingBox.minY * hImg
                   let wBboxImg       = observation.boundingBox.width * wImg
                   let hBboxImg       = observation.boundingBox.height * hImg
                   let xImg = offsetBboxXImg +  pt.x * observation.boundingBox.width * wImg
                   let yImg = offsetBboxYImg +  pt.y * observation.boundingBox.height * hImg
                   
                   let xUI =                   xImg  * alpha
                   let yUI = hMinUI +  (hImg - yImg) * alpha
                   
                      MyRect(
                       color: .blue,
                       offsetX: xUI,
                       offsetY: yUI,
                       width: 5,
                       height: 5
                      )
               }
               
               ForEach(0 ..< observation.landmarks!.rightEye!.normalizedPoints.count) { i in
                   let point = observation.landmarks!.rightEye!.normalizedPoints[i]
                   let pointOffsetX =                  point.x  * wImg * alpha
                   let pointOffsetY = hMinUI +  (1.0 - point.y) * hImg * alpha
                   
                      MyRect(
                       color: .red,
                       offsetX: pointOffsetX,
                       offsetY: pointOffsetY,
                       width: 5,
                       height: 5
                      )
               }
               ForEach(0 ..< observation.landmarks!.outerLips!.normalizedPoints.count) { i in
                   let point = observation.landmarks!.outerLips!.normalizedPoints[i]
                   let pointOffsetX =                  point.x  * wImg * alpha
                   let pointOffsetY = hMinUI +  (1.0 - point.y) * hImg * alpha
                   
                      MyRect(
                       color: .red,
                       offsetX: pointOffsetX,
                       offsetY: pointOffsetY,
                       width: 5,
                       height: 5
                      )
               }
           }
       }
    }
}



struct MarkerPreview: View {
    let observations: [VNFaceObservation]
    var body: some View {
        ForEach(observations, id: \.uuid) { observation in
            Text(observation.debugDescription)
        }
    }
}

struct MarkerPreviewLoader: View {
    
    private let img = UIImage(named: "TestImage3")!
    @State private var status = "ongoing"
    @State private var observations: [VNFaceObservation] = []
    
    var body: some View {
        VStack {
            Text(self.status).onAppear {
                detectFacesWithLandmarks(uiImage: img) { obs in
                    self.observations = obs
                    self.status = "done: \(obs.count) observations"
                }
            }
            
            ZStack {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                MarkerView(observations: self.observations, image: img)
            }

            
        }
    }
}

struct MarkerView_Previews: PreviewProvider {
    static var previews: some View {
        MarkerPreviewLoader()
    }
}
