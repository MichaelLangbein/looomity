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
               
               
//               let arImg = image.size.width / image.size.height
//               let arUI  = geo.size.width   / geo.size.height
//
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
               

               ForEach(0 ..< observation.landmarks!.outerLips!.normalizedPoints.count) { i in
                   let point = observation.landmarks!.outerLips!.normalizedPoints[i]
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
//               ForEach(0 ..< observation.landmarks!.leftEyebrow!.normalizedPoints.count) { i in
//                   let pt = observation.landmarks!.leftEyebrow!.normalizedPoints[i]
//
//                   let offsetBboxXImg = observation.boundingBox.minX * wImg
//                   let offsetBboxYImg = observation.boundingBox.minY * hImg
//                   let wBboxImg       = observation.boundingBox.width * wImg
//                   let hBboxImg       = observation.boundingBox.height * hImg
//                   let xImg = offsetBboxXImg +  pt.x * observation.boundingBox.width * wImg
//                   let yImg = offsetBboxYImg +  pt.y * observation.boundingBox.height * hImg
//
//                   let xUI =                   xImg  * alpha
//                   let yUI = hMinUI +  (hImg - yImg) * alpha
//
//                      MyRect(
//                       color: .red,
//                       offsetX: xUI,
//                       offsetY: yUI,
//                       width: 5,
//                       height: 5
//                      )
//               }
//               ForEach(0 ..< observation.landmarks!.rightEyebrow!.normalizedPoints.count) { i in
//                   let pt = observation.landmarks!.rightEyebrow!.normalizedPoints[i]
//
//                   let offsetBboxXImg = observation.boundingBox.minX * wImg
//                   let offsetBboxYImg = observation.boundingBox.minY * hImg
//                   let wBboxImg       = observation.boundingBox.width * wImg
//                   let hBboxImg       = observation.boundingBox.height * hImg
//                   let xImg = offsetBboxXImg +  pt.x * observation.boundingBox.width * wImg
//                   let yImg = offsetBboxYImg +  pt.y * observation.boundingBox.height * hImg
//
//                   let xUI =                   xImg  * alpha
//                   let yUI = hMinUI +  (hImg - yImg) * alpha
//
//                      MyRect(
//                       color: .blue,
//                       offsetX: xUI,
//                       offsetY: yUI,
//                       width: 5,
//                       height: 5
//                      )
//               }
//               let faceBoundingBox = observation.boundingBox.scaled(to: self.view.bounds.size)
//               let points = convertPointsForFace(observation.landmarks?.leftEye, faceBoundingBox)
           }
       }
    }
    
//    func convertPointsForFace(_ landmark: VNFaceLandmarkRegion2D?, _ boundingBox: CGRect) -> [(x: CGFloat, y: CGFloat)] {
//         if let points = landmark?.normalizedPoints, let count = landmark?.pointCount {
//             let convertedPoints = convert(points, with: count)
//
//             let faceLandmarkPoints = convertedPoints.map { (point: (x: CGFloat, y: CGFloat)) -> (x: CGFloat, y: CGFloat) in
//                 let pointX = point.x * boundingBox.width + boundingBox.origin.x
//                 let pointY = point.y * boundingBox.height + boundingBox.origin.y
//                 return (x: pointX, y: pointY)
//             }
//             return faceLandmarkPoints
//         }
//     }
//
//     func draw(points: [(x: CGFloat, y: CGFloat)]) {
//         let newLayer = CAShapeLayer()
//         newLayer.strokeColor = UIColor.red.cgColor
//         newLayer.lineWidth = 2.0
//
//         let path = UIBezierPath()
//         path.move(to: CGPoint(x: points[0].x, y: points[0].y))
//         for i in 0..<points.count - 1 {
//             let point = CGPoint(x: points[i].x, y: points[i].y)
//             path.addLine(to: point)
//             path.move(to: point)
//         }
//         path.addLine(to: CGPoint(x: points[0].x, y: points[0].y))
//         newLayer.path = path.cgPath
//
//         shapeLayer.addSublayer(newLayer)
//     }
//
//
//     func convert(_ points: UnsafePointer<vector_float2>, with count: Int) -> [(x: CGFloat, y: CGFloat)] {
//         var convertedPoints = [(x: CGFloat, y: CGFloat)]()
//         for i in 0...count {
//             convertedPoints.append((CGFloat(points[i].x), CGFloat(points[i].y)))
//         }
//
//         return convertedPoints
//     }
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
