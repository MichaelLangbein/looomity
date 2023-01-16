//
//  CameraView.swift
//  Loomity
//
//  Created by Michael Langbein on 16.01.23.
//  Based on https://www.youtube.com/watch?v=ZmPJBiwgZoQ
//

import SwiftUI
import AVFoundation


/**
 UIKit Standard-Pattern
 Service
    Accesses some system-process
    Connects the processes output to a delegate
 Delegate
    Glue code between service and controller
 Controller
    Uses process-output in a view
 
 Example 1: SceneKit
 Example 2: AVFoundation
 */


/**
 Device <---- a hardware device
    Input
    Output
 Session <----- the capture session
    addInput(    AVCaptureDeviceInput(device)    )  <-- the device
    addOutput(  AVCapturePhotoOutput()            )  <-- a photo-canvas
 PreviewLayer <--- a UIKit Layer where session-output is projected onto
    session
 Delegate <------ a class that takes the taken photo
 */
class CameraService {
    
    var session: AVCaptureSession?
    var delegate: AVCapturePhotoCaptureDelegate?
//    var devicePosition: AVCaptureDevice.Position = .back
    
    let output = AVCapturePhotoOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    func start(delegate: AVCapturePhotoCaptureDelegate, completion: @escaping (Error?) -> ()) {
        self.delegate = delegate
        checkPermissions(completion: completion)
    }
    
//    func setPosition(position: AVCaptureDevice.Position) {
//        https://developer.apple.com/documentation/avfoundation/capture_setup/choosing_a_capture_device
//        self.devicePosition = position
//        self.setupCamera()
//    }
//    private func getBestDevice(position: AVCaptureDevice.Position) {
//        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera, .builtInTrueDepthCamera, .builtInTripleCamera, .builtInDualWideCamera, .builtInUltraWideCamera], mediaType: .video, position: position)
//
//    }
    
    func capturePhoto(with settings: AVCapturePhotoSettings = AVCapturePhotoSettings()) {
        output.capturePhoto(with: settings, delegate: self.delegate!)
    }
    
    private func checkPermissions(completion: @escaping (Error?) -> ()) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async {
                    self?.setupCamera(completion: completion)
                }
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            setupCamera(completion: completion)
        @unknown default:
            break
        }
    }
    
    private func setupCamera(completion: @escaping (Error?) -> ()) {
        let session = AVCaptureSession()
        if let device = AVCaptureDevice.default(for: .video) { // @TODO: replace with `getBestDevice(direction)
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                if session.canAddOutput(output) {
                    session.addOutput(output)
                }
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session
                session.startRunning()
                self.session = session
                
            } catch {
                completion(error)
            }
            
        }
    }
}


class PhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let parent: CameraView
    private var didFinishProcessingPhoto: (Result<AVCapturePhoto, Error>) -> ()
    
    init(parent: CameraView, didFinishProcessingPhoto: @escaping (Result<AVCapturePhoto, Error>) -> ()) {
        self.parent = parent
        self.didFinishProcessingPhoto = didFinishProcessingPhoto
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            didFinishProcessingPhoto(.failure(error))
            return
        }
        didFinishProcessingPhoto(.success(photo))
    }
}


struct CameraView: UIViewControllerRepresentable {
    
    let cameraService: CameraService
    let didFinishProcessingPhoto: (Result<AVCapturePhoto, Error>) -> ()
    
    func makeUIViewController(context: Context) -> UIViewController {
        
        cameraService.start(delegate: context.coordinator) { error in
            if let error = error {
                didFinishProcessingPhoto(.failure(error))
                return
            }
        }
        
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground
        viewController.view.layer.addSublayer(cameraService.previewLayer)
        cameraService.previewLayer.frame = viewController.view.bounds
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
    
    func makeCoordinator() -> PhotoDelegate {
        PhotoDelegate(parent: self, didFinishProcessingPhoto: didFinishProcessingPhoto)
    }
}

struct CustomCameraView: View {
    
    let cameraService = CameraService()
    @Binding var capturedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        ZStack {
            CameraView(cameraService: cameraService) { result in
                switch result {
                case .success(let photo):
                    if let data = photo.fileDataRepresentation() {
                        self.capturedImage = UIImage(data: data)
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        print("Error: no image data found")
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
            
            VStack {
                Spacer()
                Button {
                    cameraService.capturePhoto()
                } label: {
                    Image(systemName: "circle")
                        .font(.system(size: 72))
                        .foregroundColor(.white)
                }
                .padding(.bottom)
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
