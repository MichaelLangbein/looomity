// Adjusted from https://gist.github.com/schickling/b5d86cb070130f80bb40

import UIKit

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
            fatalError()
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
            fatalError()
        }
        
        guard let thisImage = self.cgImage else { return self } // @TODO: Is this ok?
        
        guard let context = CGContext.init(
            data: nil,
            width: Int(size.width), height: Int(size.height),
            bitsPerComponent: thisImage.bitsPerComponent,
            bytesPerRow: 0,
            space: thisImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: thisImage.bitmapInfo.rawValue
        )
        else { return self }

        context.concatenate(transform)
        
        switch imageOrientation {
        case UIImage.Orientation.left, UIImage.Orientation.leftMirrored, UIImage.Orientation.right, UIImage.Orientation.rightMirrored:
            let rect = CGRectMake(0, 0, size.height, size.width)
            context.draw(thisImage, in: rect)
            break
        default:
            let rect = CGRectMake(0, 0, size.width, size.height)
            context.draw(thisImage, in: rect)
            break
        }
        
        guard let cgImage: CGImage = context.makeImage() else { return self }
        
        return UIImage(cgImage: cgImage)
    }
}

