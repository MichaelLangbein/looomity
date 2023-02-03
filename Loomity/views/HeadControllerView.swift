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

    // Function that allows us to go back programmatically
    @Environment(\.dismiss) var dismiss
    
    @State var observations: [VNFaceObservation] = []
    @State var showHelp = false
    @StateObject var taskQueue = Queue<SKVTask>()
    @State var opacity = 0.65
    @State var activeFace: UUID?
    @State var imageSaved = false
    @State var imageSaveError = false
    @State var imageSaveErrorMessage = ""
    @State var alertNoFacesDetected = false
    @State var orientation = UIDeviceOrientation.unknown
    
    var body: some View {
        ZStack {
            
            HeadView(
                image: image,
                observations: observations,
                taskQueue: taskQueue,
                usesOrthographicCam: false,
                onImageSaved: onImageSaved,
                onImageSaveError: onImageSaveError,
                opacity: $opacity,
                activeFace: $activeFace
            ).ignoresSafeArea()
            
            if orientation == .landscapeRight || orientation == .landscapeLeft {
                HStack {
                    Spacer()
                    VStack {
                        controlButtons
                        opacitySlider
                    }
                    .frame(width: 0.2 * UIScreen.main.bounds.width)
                    .padding()
                    .background(.background.opacity(0.7)) // (.gray.opacity(0.2))
                    .cornerRadius(15)
                }
            }
            else {
                VStack {
                    Spacer()
                    VStack {
                        opacitySlider
                        HStack {
                            controlButtons
                        }
                    }
                    .padding()
                    .background(.background.opacity(0.7)) // (.gray.opacity(0.2))
                    .cornerRadius(15)
                }
            }
            
        }
        .navigationBarTitle("Analysis", displayMode: .inline)
        .toolbar {
            Button {
                showHelp = true
            } label: {
                Label("Help", systemImage: "questionmark.circle")
            }
        }
        .onAppear {
            print("HeadController: starting detection of faces ...")
            detectFacesWithLandmarks(uiImage: self.image) { observations in
                print("... HeadController has detected \(observations.count) faces")
                self.observations = observations
                if self.observations.count < 1 {
                    self.alertNoFacesDetected = true
                }
            }
        }
        .alert(
            "Couldn't detect any faces in your image.",
            isPresented: $alertNoFacesDetected,
            actions: {
                Button("Continue") {}
                Button("Pick another photo") { dismiss() }
            },
            message: {Text("However, you can always place a model manually by tapping on 'Add model'.")}
        )
        .sheet(isPresented: $showHelp) {
            TutorialView(show: $showHelp)
        }
        .onRotate { newOrientation in
            orientation = newOrientation
            taskQueue.enqueue(SKVTask(type: .recenterView))
        }
    }
    
    var opacitySlider: some View {
        VStack {
            Slider(value: $opacity, in: 0.0 ... 1.0)
            Text("Opacity: \(Int(opacity * 100))%")
                .fontWeight(.light)
                .dynamicTypeSize(.small)
        }
    }
    
    @State var showRemoveModelModal = false
    var controlButtons: some View {
        Group {
            // Add or remove model
            if activeFace == nil {
                Button {
                    taskQueue.enqueue(SKVTask(type: .addNode))
                } label: {
                    Text("Add model").frame(maxWidth: .infinity)
                }.buttonStyle(.borderedProminent)
                    
            }
            if activeFace != nil {
                Button {
                    self.showRemoveModelModal = true
                } label: {
                    Text("Remove model").frame(maxWidth: .infinity)
                }
//                .buttonStyle(.bordered)
                .alert(
                    "Do you really want to remove this model?",
                    isPresented: $showRemoveModelModal,
                    actions: {
                        Button("Remove") { taskQueue.enqueue(SKVTask(type: .removeNode, payload: activeFace)) }
                        Button("Cancel") { showRemoveModelModal = false }
                    }
                )
            }
            
            Button {
                taskQueue.enqueue(SKVTask(type: .recenterView))
            } label: {
                Text("Center").frame(maxWidth: .infinity)
            }.buttonStyle(.borderedProminent)

            // Save image
            Button {
                taskQueue.enqueue((SKVTask(type: .takeScreenshot)))
            } label: {
                Text("Save image").frame(maxWidth: .infinity)
            }.alert("Image saved", isPresented: $imageSaved) {
                Button("OK") {}
            }.alert(imageSaveErrorMessage, isPresented: $imageSaveError) {
                Button("Continue") {}
            }.buttonStyle(.borderedProminent)

        }
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
        let img = UIImage(named: "TestImage2")!
        HeadControllerView(image: img)
    }
}
