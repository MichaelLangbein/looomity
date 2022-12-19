//
//  ImagePickerView.swift
//  Looomity
//
//  Created by Michael Langbein on 05.11.22.
//

import SwiftUI


// Adjusted from https://gist.github.com/schickling/b5d86cb070130f80bb40
extension UIImage {

    func fixedOrientation() -> UIImage {
        
        if imageOrientation == UIImage.Orientation.up {
            return self
        }
        
        var transform: CGAffineTransform = CGAffineTransformIdentity
        
        switch imageOrientation {
        case UIImage.Orientation.down, UIImage.Orientation.downMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, size.height)
            transform = CGAffineTransformRotate(transform, .pi)
            break
        case UIImage.Orientation.left, UIImage.Orientation.leftMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0)
            transform = CGAffineTransformRotate(transform, .pi / 2)
            break
        case UIImage.Orientation.right, UIImage.Orientation.rightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, size.height)
            transform = CGAffineTransformRotate(transform, -.pi / 2)
            break
        case UIImage.Orientation.up, UIImage.Orientation.upMirrored:
            break
        @unknown default:
            <#fatalError()#>
        }
        
        switch imageOrientation {
        case UIImage.Orientation.upMirrored, UIImage.Orientation.downMirrored:
            CGAffineTransformTranslate(transform, size.width, 0)
            CGAffineTransformScale(transform, -1, 1)
            break
        case UIImage.Orientation.leftMirrored, UIImage.Orientation.rightMirrored:
            CGAffineTransformTranslate(transform, size.height, 0)
            CGAffineTransformScale(transform, -1, 1)
        case UIImage.Orientation.up, UIImage.Orientation.down, UIImage.Orientation.left, UIImage.Orientation.right:
            break
        @unknown default:
            <#fatalError()#>
        }
        
        let ctx = CGContext.init(
            data: nil,
            width: Int(size.width), height: Int(size.height),
            bitsPerComponent: self.cgImage!.bitsPerComponent,
            bytesPerRow: 0,
            space: self.cgImage!.colorSpace!,
            bitmapInfo: self.cgImage!.bitmapInfo.rawValue
        )!
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case UIImage.Orientation.left, UIImage.Orientation.leftMirrored, UIImage.Orientation.right, UIImage.Orientation.rightMirrored:
            let rect = CGRectMake(0, 0, size.height, size.width)
            ctx.draw(self.cgImage!, in: rect)
            break
        default:
            let rect = CGRectMake(0, 0, size.width, size.height)
            ctx.draw(self.cgImage!, in: rect)
            break
        }
        
        let cgImage: CGImage = ctx.makeImage()!
        
        return UIImage(cgImage: cgImage)
    }
}



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
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        var parent: ImagePickerView
     
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
    
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                var rotatedImage = image
                parent.image = rotatedImage.fixedOrientation()
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
            else if image != nil {
                Image(uiImage: image!).resizable().scaledToFit()
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

