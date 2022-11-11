//
//  ImagePickerView.swift
//  Looomity
//
//  Created by Michael Langbein on 05.11.22.
//

import SwiftUI


struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    // select .camera here to get the image from the camera
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
     
        var parent: ImagePickerView
     
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
    
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

}

struct PickerContainerView: View {
    @State var image: UIImage?
    @State var presented = false
    
    var body: some View {
        VStack {
            if image != nil {
                Image(uiImage: image!).resizable().scaledToFit()
            }
            Button("Open picker") {
                presented = true
            }
        }.sheet(isPresented: $presented) {
            ImagePickerView(image: $image, sourceType: .photoLibrary)
        }
    }
}

struct ImagePickerView_Previews: PreviewProvider {
    static var previews: some View {
        return PickerContainerView()
    }
}

