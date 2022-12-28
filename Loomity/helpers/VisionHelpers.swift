//
//  DetectFace.swift
//  Looomity
//
//  Created by Michael Langbein on 05.11.22.
//

import UIKit
import Vision


func detectFace(uiImage: UIImage, callback: @escaping ([VNFaceObservation]) -> Void) {
    guard let cgImage = uiImage.cgImage else { return }
    guard let orientation = CGImagePropertyOrientation(
        rawValue: UInt32(uiImage.imageOrientation.rawValue)) else {return}
    
    let request = VNDetectFaceRectanglesRequest()
    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

    DispatchQueue.global().async {
        try? handler.perform([request])
        guard let observations = request.results else { return }
        DispatchQueue.main.async {
            callback(observations)
        }
    }
}

func detectLandmarks(uiImage: UIImage, observations: [VNFaceObservation], callback: @escaping ([VNFaceObservation]) -> Void) {
    guard let cgImage = uiImage.cgImage else { return }
    guard let orientation = CGImagePropertyOrientation(
        rawValue: UInt32(uiImage.imageOrientation.rawValue)) else {return}
    
    let request = VNDetectFaceLandmarksRequest()
    request.inputFaceObservations = observations
    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

    DispatchQueue.global().async {
        try? handler.perform([request])
        guard let observations = request.results else { return }
        DispatchQueue.main.async {
            callback(observations)
        }
    }
}


