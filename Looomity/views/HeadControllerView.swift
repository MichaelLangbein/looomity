//
//  HeadControllerView.swift
//  Looomity
//
//  Created by Michael Langbein on 26.12.22.
//

import SwiftUI
import Vision

struct HeadControllerView: View {
    
    // Image
    var image: UIImage
    // Parameters for detected faces
    var observations: [VNFaceObservation]
    // Communication with HeadView
    @StateObject var taskQueue = Queue<SKVTask>()
    @State var opacity = 1.0
    @State var activeFace: UUID?
    @State var usesOrthographicCam = false
    @State var imageSaved = false
    @State var imageSaveError = false
    @State var imageSaveErrorMessage = ""


    
    var body: some View {

        ZStack {
            HeadView(
                image: image,
                observations: observations,
                taskQueue: taskQueue,
                usesOrthographicCam: usesOrthographicCam,
                onImageSaved: onImageSaved,
                onImageSaveError: onImageSaveError,
                opacity: opacity,
                activeFace: $activeFace
            )
            
            VStack {
                Spacer()
                Group {
                    Slider(value: $opacity, in: 0.0 ... 1.0)
                    Text("Opacity: \(Int(opacity * 100))%")

                    HStack {
                        // Add or remove model
                        if activeFace == nil {
                            Button("Add model") {
                                taskQueue.enqueue(SKVTask(type: .addNode))
                            }
                        }
                        if activeFace != nil {
                            Button("Remove model") {
                                taskQueue.enqueue(SKVTask(type: .removeNode, payload: activeFace))
                            }
                        }

                        // Toggle cam-mode
                        Button("Use \(usesOrthographicCam ? "perspective" : "orthographic") camera") {
                            if usesOrthographicCam == true {
                                taskQueue.enqueue(SKVTask(type: .setPerspectiveCam))
                                usesOrthographicCam = false
                            } else {
                                taskQueue.enqueue(SKVTask(type: .setOrthographicCam))
                                usesOrthographicCam = true
                            }
                        }

                        // Save image
                        Button("Save image") {
                            taskQueue.enqueue((SKVTask(type: .takeScreenshot)))
                        }.alert("Image saved", isPresented: $imageSaved) {
                            Button("OK") {}
                        }.alert(imageSaveErrorMessage, isPresented: $imageSaveError) {
                            Button("Continue") {}
                        }

                    }

                }.background(.white)
            }
            .padding()
            
        }
        .navigationBarTitle("Analysis")
    }

    func onImageSaved() {
        imageSaved = true
    }
    
    func onImageSaveError(error: Error) {
        imageSaveError = true
        imageSaveErrorMessage = error.localizedDescription
    }
}

struct HeadControllerView_Previews: PreviewProvider {
    static var previews: some View {
        
        
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
        
        let img = UIImage(named: "TestImage2")!
        
        HeadControllerView(image: img, observations: [observation1, observation2])
    }
}
