//
//  Experiments.swift
//  Looomity
//
//  Created by Michael Langbein on 17.12.22.
//

import SwiftUI

struct Experiments: View {
    
    @State var opacity = 1.0
    @StateObject var taskQueue = Queue<SKVTask>()
    @State var activeFace: UUID?
    @State var usesOrthographicCam = false
    @State var imageSaved = false
    @State var imageSaveError = false
    @State var imageSaveErrorMessage = ""

       var body: some View {
           HStack {
               Spacer()
               VStack {
                   controlButtons
                   opacitySlider
               }
               .frame(width: 0.5 * UIScreen.main.bounds.width)
               .padding()
               .background(.background.opacity(0.8))
               .cornerRadius(15)
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
                    taskQueue.enqueue(SKVTask(type: .removeNode, payload: activeFace))
                } label: {
                    Text("Remove model").frame(maxWidth: .infinity)
                }.buttonStyle(.borderedProminent)
            }

            // Toggle cam-mode
            Button {
                if usesOrthographicCam == true {
                    taskQueue.enqueue(SKVTask(type: .setPerspectiveCam))
                    usesOrthographicCam = false
                } else {
                    taskQueue.enqueue(SKVTask(type: .setOrthographicCam))
                    usesOrthographicCam = true
                }
            } label: {
                Text("Use \(usesOrthographicCam ? "perspective" : "ortho") view").frame(maxWidth: .infinity)
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
    
}

struct Experiments_Previews: PreviewProvider {
    static var previews: some View {
        Experiments()
    }
}
