//
//  ViewAsImageExtension.swift
//  Looomity
//
//  Created by Michael Langbein on 26.12.22.
//

import SwiftUI


extension View {
    func asImage() -> UIImage {
        let controller = UIHostingController(rootView: self)

        // locate far out of screen
        controller.view.frame = CGRect(x: 0, y: CGFloat(Int.max), width: 1, height: 1)
        UIApplication.shared.windows.first!.rootViewController?.view.addSubview(controller.view)

        let size = controller.sizeThatFits(in: UIScreen.main.bounds.size)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.sizeToFit()
        controller.view.backgroundColor = .clear
        let image = controller.view.asImage()
        controller.view.removeFromSuperview()
        return image
    }
}

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
// [!!] Uncomment to clip resulting image
//             rendererContext.cgContext.addPath(
//                UIBezierPath(roundedRect: bounds, cornerRadius: 20).cgPath)
//            rendererContext.cgContext.clip()

// As commented by @MaxIsom below in some cases might be needed
// to make this asynchronously, so uncomment below DispatchQueue
// if you'd same met crash
//            DispatchQueue.main.async {
                 layer.render(in: rendererContext.cgContext)
//            }
        }
    }
}


// TESTING
struct TestableView: View {
    var body: some View {
        VStack {
            Text("Test 1")
            Text("Test 2")
        }
    }
}

struct TestBackgroundRendering: View {
    var body: some View {
        VStack {
            TestableView()
            Divider()
            Image(uiImage: render())
                .border(Color.black)
        }
    }
    
    private func render() -> UIImage {
        TestableView().asImage()
    }
}
