// Adjusted from https://gist.github.com/schickling/b5d86cb070130f80bb40

import UIKit

extension UIImage {

    func fixedOrientation() -> UIImage {
        
        if imageOrientation == .up {
            return self
        }
        
        var transform: CGAffineTransform = CGAffineTransformIdentity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, size.height)
            transform = CGAffineTransformRotate(transform, .pi)
            break
        case .left, .leftMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0)
            transform = CGAffineTransformRotate(transform, .pi / 2)
            break
        case .right, .rightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, size.height)
            transform = CGAffineTransformRotate(transform, -.pi / 2)
            break
        case .up, .upMirrored:
            break
        @unknown default:
            fatalError()
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            CGAffineTransformTranslate(transform, size.width, 0)
            CGAffineTransformScale(transform, -1, 1)
            break
        case .leftMirrored, .rightMirrored:
            CGAffineTransformTranslate(transform, size.height, 0)
            CGAffineTransformScale(transform, -1, 1)
        case .up, .down, .left, .right:
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
        case .left, .leftMirrored, .right, .rightMirrored:
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

