//
//  ImagePickerView.swift
//  Looomity
//
//  Created by Michael Langbein on 05.11.22.
//

import SwiftUI


struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var show: Bool
    // select .camera here to get the image from the camera
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        var parent: ImagePickerView
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
    
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                if let fixedImage = image.fixedOrientation() {
                    parent.image = fixedImage
                }
            }
            parent.show = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.show = false
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
            if presented {
                ImagePickerView(image: $image, show: $presented)
            }
            else if let img = image {
                Image(uiImage: img).resizable().scaledToFit()
            }
            Button("Open picker") {
                presented = true
            }
        }
    }
}

struct ImagePickerView_Previews: PreviewProvider {
    static var previews: some View {
        return PickerContainerView()
    }
}

