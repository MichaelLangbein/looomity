//
//  CameraView.swift
//  Loomity
//
//  Created by Michael Langbein on 16.01.23.
//  Based on https://www.youtube.com/watch?v=ZmPJBiwgZoQ
//

import SwiftUI
import AVFoundation



enum ProcessingError: Error {
    case errorWhileProcessing
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    private var cameraManager: CameraManager
    private var handlePhoto: (Result<UIImage, Error>) -> ()
    
    init(
        cameraManager: CameraManager,
        didFinishProcessingPhoto: @escaping (Result<UIImage, Error>) -> ()
    ) {
        self.cameraManager = cameraManager
        self.handlePhoto = didFinishProcessingPhoto
        
        super.init(nibName: nil, bundle: nil)
        
        cameraManager.start(delegate: self) { error in
            if let error = error {
                didFinishProcessingPhoto(.failure(error))
                return
            }
        }
        self.view.backgroundColor = .systemBackground
        self.view.layer.addSublayer(cameraManager.previewLayer)
        self.cameraManager.previewLayer.frame = self.view.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let newOrientation = self.view.window?.windowScene?.interfaceOrientation
        self.cameraManager.willTransition(size: size, newOrientation: newOrientation)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            handlePhoto(.failure(error))
            return
        }
        guard
            let data = photo.fileDataRepresentation(),
            let uiImage = UIImage(data: data)
        else {
            handlePhoto(.failure(ProcessingError.errorWhileProcessing))
            return
        }
        
        if cameraManager.devicePosition == .front {
            var trueOrientation = uiImage.imageOrientation
            switch uiImage.imageOrientation {
            case .right:                          // selfie-cam, portrait-orientation
                trueOrientation = .leftMirrored
            case .up:                             // selfie-cam, landscape-orientation (tilted right)
                trueOrientation = .upMirrored
            case .down:                           // selfie-cam, landscape-orientation (tilted left)
                trueOrientation = .downMirrored
            case .left:                           // selfie-cam, portrait orientation upside down
                trueOrientation = .rightMirrored
            default:
                trueOrientation = uiImage.imageOrientation
            }
            guard let cgImage = uiImage.cgImage else {
                handlePhoto(.success(uiImage))
                return
            }
            let imageCorrectedOrientation = UIImage(cgImage: cgImage, scale: 1.0, orientation: trueOrientation)
            guard let imageFixed = imageCorrectedOrientation.fixedOrientation() else {
                handlePhoto(.success(uiImage))
                return
            }
            handlePhoto(.success(imageFixed))

        } else {
            guard let imageFixed = uiImage.fixedOrientation() else {
                handlePhoto(.success(uiImage))
                return
            }
            handlePhoto(.success(imageFixed))
        }
    }
}

struct CameraRepresentableView: UIViewControllerRepresentable {
    let cameraManager: CameraManager
    let didFinishProcessingPhoto: (Result<UIImage, Error>) -> ()
    
    func makeUIViewController(context: Context) -> UIViewController {
        return CameraViewController(
            cameraManager: cameraManager,
            didFinishProcessingPhoto: didFinishProcessingPhoto
        )
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}

struct CustomCameraView: View {
    
    @Binding var capturedImage: UIImage?
    private let cameraManager = CameraManager()
    @State var hasTwoCameras = false
    @State var canUseFlash = false
    @State var usesFlash = false
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        ZStack {
            CameraRepresentableView(cameraManager: cameraManager) { result in
                switch result {
                case .success(let photo):
                    self.capturedImage = photo
                    presentation.wrappedValue.dismiss()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
            
            VStack {
                
                Spacer()
                
                HStack(alignment: .center) {
                    
                    Button {
                        usesFlash.toggle()
                    } label: {
                        Image(systemName: usesFlash ? "bolt" : "bolt.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .disabled(!canUseFlash)

                    
                    Spacer()
                    
                    Button {
                        cameraManager.capturePhoto(flash: usesFlash)
                    } label: {
                        Image(systemName: "circle")
                            .font(.system(size: 72))
                            .foregroundColor(.white)
                    }
                    .padding(.bottom)

                    Spacer()
                    
                    Button {
                        cameraManager.switchCamera { newCamera in
                            self.canUseFlash = newCamera.hasFlash
                        }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .disabled(!self.hasTwoCameras)
                }
                .padding(.leading)
                .padding(.trailing)
            }
        }.onAppear {
            self.hasTwoCameras = cameraManager.hasTwoCams()
            if let activeCamera = cameraManager.getCurrentDevice() {
                self.canUseFlash = activeCamera.hasFlash
            }
        }
    }
}


struct CameraPreviewView: View {
    @State private var capturedImage: UIImage? = nil
    @State private var isPresented = false
    
    var body: some View {
        ZStack {
            if capturedImage != nil {
                Image(uiImage: capturedImage!)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
            } else {
                Color(uiColor: .systemBackground)
            }
            
            VStack {
                Spacer()
                Button {
                    isPresented.toggle()
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .padding()
                .sheet(isPresented: $isPresented, content: {
                    CustomCameraView(capturedImage: $capturedImage)
                })
            }
        }
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraPreviewView()
    }
}
