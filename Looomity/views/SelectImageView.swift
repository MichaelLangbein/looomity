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
    @State var imageSelectMode: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        VStack(alignment: .center) {
            
            Spacer()
            
            if let image = self.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .border(.green)
            } else {
                Image(systemName: "person.crop.rectangle.fill")
                    .resizable().scaledToFit().padding(UIScreen.main.bounds.width / 4.0)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack {
                Button("Galery", action: pickFromGalery).buttonStyle(.borderedProminent)
                Button("Camera", action: pickFromCamera).buttonStyle(.borderedProminent)
                if let img = image {
                    NavigationLink(destination: AnalysisView(image: img)) {
                        Text("Analyze")
                    }
                }
            }

        }.sheet(isPresented: $showImagePicker) {
            ImagePickerView(image: $image, sourceType: imageSelectMode)
        }
        .navigationTitle("Select image")
    }
    
    
    func pickFromGalery() {
        imageSelectMode = .photoLibrary
        showImagePicker = true
    }
    
    func pickFromCamera() {
        imageSelectMode = .camera
        showImagePicker = true
    }
    
    func toAnalysis() {
        
    }
}

struct SelectImageView_Previews: PreviewProvider {
    static var previews: some View {
        SelectImageView()
    }
}
