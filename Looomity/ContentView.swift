//
//  ContentView.swift
//  Looomity
//
//  Created by Michael Langbein on 05.11.22.
//

import SwiftUI
import Vision



struct ContentView: View {
    @State var showSelectOptions = false
    @State var showImagePicker = false
    @State var imageSelectMode: UIImagePickerController.SourceType = .photoLibrary
    @State var image: UIImage?
    @State var observation: VNFaceObservation?
    
    var body: some View {
        VStack (alignment: .center) {
            
            Spacer()
            
            if let image = self.image {
                let ar = image.size.height / image.size.width
                let w = UIScreen.main.bounds.width * 0.9
                let h = ar * w
                
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit().border(.green)
                    
                    if let observation = self.observation {
                        HeadView(observation: observation)
                            .scaledToFit().border(.red)
                    }
                }.frame(width: w, height: h)
            }
            
            else {
                Image(systemName: "person.crop.rectangle.fill")
                    .resizable().scaledToFit().padding(UIScreen.main.bounds.width / 4.0)
                    .foregroundColor(.gray)
            }
            
            Spacer()

            HStack {
                Button("Pick image", action: onPickClicked)
                    .buttonStyle(.borderedProminent)
                    .actionSheet(isPresented: $showSelectOptions, content: getPicker)
                if image != nil {
                    Button("Analyze image", action: onAnalyzeClicked)
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("Analyze image", action: {})
                        .buttonStyle(.borderedProminent)
                        .accentColor(.gray)
                        .disabled(true)
                }


            }
        }.sheet(isPresented: $showImagePicker) {
            ImagePickerView(image: $image, sourceType: imageSelectMode)
        }.navigationBarTitle("Loomity")
    }
    
    func onPickClicked() {
        showSelectOptions = true
    }
    
    func onAnalyzeClicked() {
        if let image = self.image {
            detectFace(uiImage: image) { observations in
                guard let firstObs = observations.first else { return }
                observation = firstObs
            }
        }

    }
    
    func getPicker() -> ActionSheet {
        return ActionSheet(
            title: Text("Pick an image"),
            buttons: [
                .default(Text("From gallery"), action: pickFromGalery),
                .default(Text("Camera"), action: pickFromCamera),
                .cancel()
            ]
        )
    }
    
    func pickFromGalery() {
        imageSelectMode = .photoLibrary
        showImagePicker = true
        observation = nil
    }
    
    func pickFromCamera() {
        imageSelectMode = .camera
        showImagePicker = true
        observation = nil
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
