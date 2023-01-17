//
//  SelectImageView.swift
//  Looomity
//
//  Created by Michael Langbein on 15.12.22.
//

import SwiftUI

struct SelectImageView: View {
    @State var image: UIImage?;
    @State var showSelectOptions = false
    @State var showImagePicker = false
    @State var showCamera = false
    
    var body: some View {
        FullPageView {
            VStack(alignment: .center) {
                
                if (showImagePicker || showCamera) {
                    if (showImagePicker) {
                        ImagePickerView(image: $image, show: $showImagePicker, sourceType: .photoLibrary)
                    }
                    if (showCamera) {
                        CustomCameraView(capturedImage: $image, isDisplayed: $showCamera)
                    }
                }
                
                else {
                    Spacer()
                    
                    if let image = self.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(systemName: "person.crop.rectangle.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) / 4.0)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack {
                        HStack {
                            Button("Gallery", action: pickFromGallery).foregroundColor(.white).buttonStyle(.borderedProminent)
                            Button("Camera", action: pickFromCamera).foregroundColor(.white).buttonStyle(.borderedProminent)
                            if let img = image {
                                NavigationLink(destination: AnalysisView(image: img)) {
                                    Text("Loomify").foregroundColor(.white)
                                }.buttonStyle(.borderedProminent)
                            }
                        }.padding()
                    }.textBox()
                }
            }
        }
        .navigationBarTitle("Select image", displayMode: .inline)
    }
    
    
    func pickFromGallery() {
        showImagePicker = true
    }
    
    func pickFromCamera() {
        showCamera = true
    }
    
    func toAnalysis() {
        
    }
}

struct SelectImageView_Previews: PreviewProvider {
    static var previews: some View {
        SelectImageView()
    }
}
