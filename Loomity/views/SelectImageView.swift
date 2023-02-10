//
//  SelectImageView.swift
//  Looomity
//
//  Created by Michael Langbein on 15.12.22.
//

import SwiftUI

struct SelectImageView: View {
    @State var image: UIImage?;
    
    var body: some View {
        FullPageView {
            ZStack {
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
                
                VStack {
                    Spacer()
                    HStack {
                        NavigationLink(destination: ImagePickerView(image: $image, sourceType: .photoLibrary)) {
                            Text("Gallery")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        NavigationLink(destination: CustomCameraView(capturedImage: $image)) {
                            Text("Camera")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        if let img = image {
                            NavigationLink(destination: AnalysisView(image: img)) {
                                Text("Loomify")
                                    .frame(maxWidth: .infinity)
                            }.buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                    .background(.gray.opacity(0.4))
                    .cornerRadius(15)
                    .padding()
                }.frame(maxWidth: maxWidthBig)
            }
        }
        .navigationBarTitle("Select image", displayMode: .inline)
    }
}

struct SelectImageView_Previews: PreviewProvider {
    static var previews: some View {
        SelectImageView()
    }
}
