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
 Shared between CustomCameraView (from where it gets user-inputs)
 and CameraController (from where it gets ui-events and to which it gives its previewLayer)
 
 
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
    
    func switchCamera() {
        let newDevicePosition: AVCaptureDevice.Position = self.devicePosition == .back ?  .front :  .back
        guard
            let newDevice = self.getDevice(position: newDevicePosition),
            let session = self.session,
            let currentInput = session.inputs.first
        else { return }
        session.removeInput(currentInput)
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            if session.canAddInput(newInput) {
                session.addInput(newInput)
            }
            self.devicePosition = newDevicePosition
        } catch {
            print(error)
        }
        
//        if self.devicePosition == .back {
//            if let videoToPhotoConnection = self.output.connection(with: .video) {
//                if videoToPhotoConnection.isVideoMirroringSupported {
//                    videoToPhotoConnection.automaticallyAdjustsVideoMirroring = false
//                    videoToPhotoConnection.isVideoMirrored = true
//                }
//            }
//        } else {
//            if let videoToPhotoConnection = self.output.connection(with: .video) {
//                if videoToPhotoConnection.isVideoMirroringSupported {
//                    videoToPhotoConnection.automaticallyAdjustsVideoMirroring = false
//                    videoToPhotoConnection.isVideoMirrored = false
//                }
//            }
//        }
    }
    
    func capturePhoto(with settings: AVCapturePhotoSettings = AVCapturePhotoSettings()) {
        guard
            let videoToPhotoConnection = output.connection(with: .video),
            let videoToPreviewConnection = previewLayer.connection
        else {
            output.capturePhoto(with: settings, delegate: self.delegate!)
            return
        }
        videoToPhotoConnection.videoOrientation = videoToPreviewConnection.videoOrientation
        output.capturePhoto(with: settings, delegate: self.delegate!)
    }
        
    func willTransition(size: CGSize, newOrientation: UIInterfaceOrientation?) {
        // https://developer.apple.com/documentation/avfoundation/avcaptureconnection/1389415-videoorientation
        // https://stackoverflow.com/questions/21258372/avcapturevideopreviewlayer-landscape-orientation/62505962#62505962
        // https://stackoverflow.com/questions/26069874/what-is-the-right-way-to-handle-orientation-changes-in-ios-8
        // https://stackoverflow.com/questions/28820933/ios-viewwilltransitiontosize-and-device-orientation
        // https://stackoverflow.com/questions/30202597/preventing-avcapturevideopreviewlayer-from-rotating-but-allow-ui-layer-to-rotat

        self.previewLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        guard let connection = self.previewLayer.connection else { return }
        if connection.isVideoOrientationSupported {
            switch newOrientation {
            case .portrait:
                connection.videoOrientation = .portrait
            case .landscapeLeft:
                connection.videoOrientation = .landscapeLeft
            case .landscapeRight:
                connection.videoOrientation = .landscapeRight
            case .portraitUpsideDown:
                connection.videoOrientation = .portraitUpsideDown
            default:
                break
            }
        }
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
    
    private func getDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        switch position {
        case .front:
            return self.frontDevice
        case .back:
            return self.backDevice
        case .unspecified:
            return self.backDevice != nil ? self.backDevice : self.frontDevice
        @unknown default:
            return self.backDevice != nil ? self.backDevice : self.frontDevice
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
            session.startRunning()
            self.session = session
            
        } catch {
            completion(error)
        }
            
    }
}


enum ProcessingError: Error {
    case errorWhileProcessing
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    private var cameraService: CameraService
    private var didFinishProcessingPhoto: (Result<UIImage, Error>) -> ()
    
    init(
        cameraService: CameraService,
        didFinishProcessingPhoto: @escaping (Result<UIImage, Error>) -> ()
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
        let newOrientation = self.view.window?.windowScene?.interfaceOrientation
        self.cameraService.willTransition(size: size, newOrientation: newOrientation)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            didFinishProcessingPhoto(.failure(error))
            return
        }
        let data = photo.fileDataRepresentation()!
        let uiImage = UIImage(data: data)!
        if cameraService.devicePosition == .front {
            let imageFixed = uiImage.fixedOrientation()
        
            /**
                @TODO:
                    uiImage has orientation = .right
                    when I call uiImage.withOrientationFlippedHorizontally(), I get .rightMirrored ...
                    ... which weirdly doesn't help when then called with .fixedOrientation().
             */
            var transform = CGAffineTransformIdentity
            transform = CGAffineTransformTranslate(transform, imageFixed.size.width, 0)
            transform = CGAffineTransformScale(transform, -1.0, 1.0)
            guard let cgImage = imageFixed.cgImage else { didFinishProcessingPhoto(.success(imageFixed)); return }
            guard let context = CGContext.init(
                data: nil,
                width: Int(imageFixed.size.width), height: Int(imageFixed.size.height),
                bitsPerComponent: cgImage.bitsPerComponent,
                bytesPerRow: 0,
                space: cgImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: cgImage.bitmapInfo.rawValue
            )  else { didFinishProcessingPhoto(.success(imageFixed)); return }
            context.concatenate(transform)
            let rect = CGRectMake(0, 0, imageFixed.size.width, imageFixed.size.height)
            context.draw(cgImage, in: rect)
            guard let newCgImage = context.makeImage() else { didFinishProcessingPhoto(.success(imageFixed)); return }
            let imageFixed2 = UIImage(cgImage: newCgImage)
            didFinishProcessingPhoto(.success(imageFixed2))

        } else {
            let imageFixed = uiImage.fixedOrientation()
            didFinishProcessingPhoto(.success(imageFixed))
        }
    }
}

struct CameraRepresentableView: UIViewControllerRepresentable {
    let cameraService: CameraService
    let didFinishProcessingPhoto: (Result<UIImage, Error>) -> ()
    
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
            CameraRepresentableView(cameraService: cameraService) { result in
                switch result {
                case .success(let photo):
                    self.capturedImage = photo
                    self.isDisplayed = false
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
