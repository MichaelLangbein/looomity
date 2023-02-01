//
//  ImagePickerView.swift
//  Looomity
//
//  Created by Michael Langbein on 05.11.22.
//

import SwiftUI


struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    // select .camera here to get the image from the camera
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Environment(\.presentationMode) var presentation

    
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
                } else {
                    parent.image = image
                }
                parent.presentation.wrappedValue.dismiss()
            }
        }
        
//        , UINavigationBarDelegate
//        func navigationBar(_ navigationBar: UINavigationBar, shouldPush item: UINavigationItem) -> Bool {
//        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentation.wrappedValue.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

}

struct PickerContainerView: View {
    @State var image: UIImage?
    
    var body: some View {
        VStack {
            ImagePickerView(image: $image)
        }
    }
}

struct ImagePickerView_Previews: PreviewProvider {
    static var previews: some View {
        return PickerContainerView()
    }
}

