//
//  CameraManager.swift
//  Loomity
//
//  Created by Michael Langbein on 20.01.23.
//

import AVFoundation
import UIKit


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
class CameraManager: ObservableObject {
    
    var session: AVCaptureSession?
    var delegate: AVCapturePhotoCaptureDelegate?
    @Published var devicePosition: AVCaptureDevice.Position = .back
    var frontDevice: AVCaptureDevice?
    var backDevice: AVCaptureDevice?
    let output = AVCapturePhotoOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()

    func start(delegate: AVCapturePhotoCaptureDelegate, onError: @escaping (Error?) -> ()) {
        self.delegate = delegate
        self.detectCameras()
        self.checkPermissions { permission in
            guard permission else { return }
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.setupCamera(handleError: onError)
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
    
    private func setupCamera(handleError: @escaping (Error?) -> ()) {
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
            handleError(error)
        }
            
    }
}
