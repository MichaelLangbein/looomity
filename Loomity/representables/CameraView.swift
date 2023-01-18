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
    var devicePosition: AVCaptureDevice.Position = .back
    var frontDevice: AVCaptureDevice?
    var backDevice: AVCaptureDevice?
    let output = AVCapturePhotoOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()

    func start(delegate: AVCapturePhotoCaptureDelegate, completion: @escaping (Error?) -> ()) {
        self.delegate = delegate
        self.detectCameras()
        self.checkPermissions { permission in
            guard permission else { return }
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.setupCamera(completion: completion)
            }
        }
    }
    
//    func onRotate(orientation: UIDeviceOrientation) {
//        previewLayer.videoGravity = .resizeAspectFill
//    }
    
    func switchCamera() {
        self.devicePosition = self.devicePosition == .back ?  .front :  .back
        guard
            let newDevice = self.getCurrentDevice(),
            let session = self.session,
            let currentInput = session.inputs.first
        else { return }
        session.removeInput(currentInput)
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            if session.canAddInput(newInput) {
                session.addInput(newInput)
            }
            if devicePosition == .front {
                previewLayer.transform = CATransform3DScale(CATransform3DIdentity, -1.0, 1.0, 1.0)
            } else {
                previewLayer.transform = CATransform3DIdentity
            }
        } catch {
            print(error)
        }
    }
    
    func capturePhoto(with settings: AVCapturePhotoSettings = AVCapturePhotoSettings()) {
        output.capturePhoto(with: settings, delegate: self.delegate!)
    }
    
    func hasTwoCams() -> Bool {
        return self.frontDevice != nil && self.backDevice != nil
    }
    
    private func detectCameras() {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera, .builtInTrueDepthCamera, .builtInTripleCamera, .builtInDualWideCamera, .builtInUltraWideCamera], mediaType: .video, position: .unspecified)
        let devices = discoverySession.devices
        guard !devices.isEmpty else { return }
        self.frontDevice = devices.first(where: { $0.position == .front })
        self.backDevice = devices.first(where: { $0.position == .back })
        if self.frontDevice == nil {
            self.devicePosition = .back
        }
        if self.backDevice == nil {
            self.devicePosition = .front
        }
    }
    
    private func getCurrentDevice() -> AVCaptureDevice? {
        if self.devicePosition == .front && self.frontDevice != nil {
            return self.frontDevice
        }
        if self.devicePosition == .back && self.backDevice != nil {
            return self.backDevice
        }
        return nil
    }

    private func checkPermissions(withPermission: @escaping (Bool) -> ()) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                withPermission(granted)
            }
            break
        case .authorized:
            withPermission(true)
        case .restricted, .denied:
            withPermission(false)
            break
        @unknown default:
            withPermission(false)
            break
        }
    }
    
    private func setupCamera(completion: @escaping (Error?) -> ()) {
        let session = AVCaptureSession()
        guard let device = self.getCurrentDevice() else { return }
            
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
            if devicePosition == .front {
                previewLayer.transform = CATransform3DScale(CATransform3DIdentity, -1.0, 1.0, 1.0)
            } else {
                previewLayer.transform = CATransform3DIdentity
            }
            session.startRunning()
            self.session = session
            
        } catch {
            completion(error)
        }
            
    }
}



class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    private var cameraService: CameraService
    private var didFinishProcessingPhoto: (Result<AVCapturePhoto, Error>) -> ()
    
    init(
        cameraService: CameraService,
        didFinishProcessingPhoto: @escaping (Result<AVCapturePhoto, Error>) -> ()
    ) {
        self.cameraService = cameraService
        self.didFinishProcessingPhoto = didFinishProcessingPhoto
        super.init(nibName: nil, bundle: nil)
        cameraService.start(delegate: self) { error in
            if let error = error {
                didFinishProcessingPhoto(.failure(error))
                return
            }
        }
        self.view.backgroundColor = .systemBackground
        self.view.layer.addSublayer(cameraService.previewLayer)
        self.cameraService.previewLayer.frame = self.view.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.cameraService.previewLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
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
        return CameraViewController(cameraService: cameraService, didFinishProcessingPhoto: didFinishProcessingPhoto)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}

struct CustomCameraView: View {
    
    let cameraService = CameraService()
    @Binding var capturedImage: UIImage?
    @Binding var isDisplayed: Bool
    
    var body: some View {
        ZStack {
            CameraView(cameraService: cameraService) { result in
                switch result {
                case .success(let photo):
                    if let data = photo.fileDataRepresentation() {
                        let uiImage = UIImage(data: data)!
                        self.capturedImage = uiImage.fixedOrientation()
                        self.isDisplayed = false
                    } else {
                        print("Error: no image data found")
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
            
            VStack {
                Spacer()
                
                HStack(alignment: .center) {
                    
                    Button {
                        isDisplayed = false
                    } label: {
                        Image(systemName: "arrowshape.turn.up.backward.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button {
                        cameraService.capturePhoto()
                    } label: {
                        Image(systemName: "circle")
                            .font(.system(size: 72))
                            .foregroundColor(.white)
                    }
                    .padding(.bottom)

                    Spacer()
                    
                    Button {
                        cameraService.switchCamera()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                }
                .padding(.leading)
                .padding(.trailing)
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
                    CustomCameraView(capturedImage: $capturedImage, isDisplayed: $isPresented)
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
