//
//  BOCamera.swift
//
//
//  Created by Raja on 05/09/23.
//

import UIKit
import AVFoundation
/**
 An object that create an camera preview layer.
 It uses AVFoundation  to open camera and giving callback as
 # Code
 ```
 func videoOutput(pixelBuffer: CVPixelBuffer,
                  sampleBuffer: CMSampleBuffer,
                  previewlayer: AVCaptureVideoPreviewlayer).
 func photoOutput(output: AVCapturePhoto, previewlayer: AVCaptureVideoPreviewLayer)
 func failed(error: Error)
 ```

 When adding a BOCamera to your interface, perform the following steps:
 * init(with cameraPosition: AVCaptureDevice.Position)
 * set delegate property to get call back
 * Call start(over view: UIView) to set the layer of camera preview.
 * Call stop() to stop capture session.
 * Call restart() to restart capture session.
 * Call capturePhoto() to capture current state of preview.
 * Call updateFlash() to update flash mode while camera previewing.
 # Code
 ```
 let crop = BOCamera(with: .back)
 crop.start(over: someView)
 crop.capturePhoto()
 crop.stop() on any button action
 ```
 */

class BOCamera: NSObject, BOCameraObject {

    private var cameraPosition: AVCaptureDevice.Position!
    private var setting: BOCameraSetting!
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var photoOutput = AVCapturePhotoOutput()
    private lazy var device: AVCaptureDevice? = {
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes,
                                                       mediaType: .video,
                                                       position: cameraPosition)
        return session.devices.first
    }()

    weak var delegate: BOCameraOutputDelegate?
    private let videoQueue = DispatchQueue(label: "camera_frame_processing_queue")

    required init(with cameraPostion: BOCameraPostion, setting: BOCameraSetting) {
        let position = AVCaptureDevice.Position(rawValue: cameraPostion.rawValue)
        self.cameraPosition = position ?? .back
        self.setting = setting
    }

    /// - Returns Camera Lenses support heirarchy.
    private var deviceTypes: [AVCaptureDevice.DeviceType] {
        if setting.cameraLensPriortization == .main {
            return [.builtInWideAngleCamera,//Main camera
                     .builtInUltraWideCamera,
                     .builtInDualWideCamera,
                     .builtInTripleCamera,
                     .builtInDualCamera,
                     .builtInTrueDepthCamera,
                     .builtInTelephotoCamera]
        } else {
            return [.builtInUltraWideCamera,
                     .builtInWideAngleCamera, // Main Camera
                     .builtInDualWideCamera,
                     .builtInTripleCamera,
                     .builtInDualCamera,
                     .builtInTrueDepthCamera,
                     .builtInTelephotoCamera]
        }
    }
}

/// Exposed function to show camera
extension BOCamera {
    /// Add camera preivew layer on view and start capturing the image
    ///  - Parameters view: Parentview on which camera layer should be added.
    func start(over view: UIView) {
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)
        setCameraInput()
        setCameraOutput()
    }

    /// To Restart the camera preview
    func restart() {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in // High Priority Thread
            guard let weakSelf = self else { return }
            weakSelf.captureSession.startRunning()
            weakSelf.updateDeviceConfiguration(flash: BOFlashLight.torchMode)
        }
    }

    /// To stop capturing
    func stop() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    /// Photo Capture
    /// Capture Image with giving photo output setting of high quality
    func capturePhoto() {
        let photoSettings: AVCapturePhotoSettings
        /// Checking High quality image capture supported or not
        if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            photoSettings = AVCapturePhotoSettings(format:
                                                    [AVVideoCodecKey: AVVideoCodecType.hevc])
        } else {
            let bgraFormat: [String : AnyObject] = [kCVPixelBufferPixelFormatTypeKey as String :
                                                        NSNumber(value: kCVPixelFormatType_32BGRA)]
            photoSettings = AVCapturePhotoSettings(format: bgraFormat)
        }
        photoSettings.photoQualityPrioritization = .quality
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }

    /// Change flash
    ///  - Parameters : mode to set the current flash mode if nil then its automatically change the mode in hierarchy manner
    ///  Flash Hierarchy : off -> on -> auto
    func changeFlash(mode: AVCaptureDevice.TorchMode? = nil) {
        if let mode = mode {
            BOFlashLight.torchMode = mode
        } else {
            BOFlashLight.toggle()
        }
        restart()
    }

    /// Stop Flash
    func stopFlash() {
        updateDeviceConfiguration(flash: .off)
    }

    /// - Returns Current using camera lens by device to capture image.
    var currentCameraType: AVCaptureDevice.DeviceType? {
        device?.deviceType
    }
    
    /// To set bias value which make image darker to lighter. Value should between -8 to 8.
    func setExposure(targetBias: Double) {
        guard let device = device else{ return}
        do {
            try device.lockForConfiguration()
            let bias = min(max(device.minExposureTargetBias, Float(targetBias)),
                           device.maxExposureTargetBias)
            device.setExposureTargetBias(bias, completionHandler: nil)
            device.unlockForConfiguration()
        } catch let err {
            delegate?.failed(error: err)
        }
    }
    
}

// MARK: Auto
extension BOCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            delegate?.failed(error: BOCameraError.imageBufferNotFound)
            return
        }
        delegate?.videoOutput(pixelBuffer: frame,
                              sampleBuffer: sampleBuffer,
                              previewlayer: previewLayer,
                              device: device, queue: videoQueue)
    }
}

// MARK: Manual
extension BOCamera: AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error == nil {
            _ = delegate?.photoOutput(output: photo, previewlayer: previewLayer)
        } else {
            delegate?.failed(error: error!)
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // dispose system shutter sound
        AudioServicesDisposeSystemSoundID(1108)
    }
}

/// Basic Camera Session Setup
extension BOCamera {

    // MARK: Session initialisation and video output
    private func setCameraInput() {
        guard let device = device else {
            delegate?.failed(error: BOCameraError.cameraNotFound)
            return
        }
        do {
            let cameraInput = try AVCaptureDeviceInput(device: device)
            self.captureSession.beginConfiguration()
            if captureSession.canAddInput(cameraInput) {
                self.captureSession.addInput(cameraInput)
            }
            self.captureSession.commitConfiguration()
        } catch let err {
            delegate?.failed(error: err)
            return
        }
    }

    // MARK: Set Camera output
    private func setCameraOutput() {
        let videSetting = [(kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: kCVPixelFormatType_32BGRA)]
        self.videoDataOutput.videoSettings = videSetting as [String: Any]
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
        if setting.enableAutoDetection {
            self.videoDataOutput.setSampleBufferDelegate(self,
                                                         queue: videoQueue)

        }
        self.photoOutput.maxPhotoQualityPrioritization = .quality
        self.captureSession.beginConfiguration()
        if captureSession.canAddOutput(videoDataOutput) {
            self.captureSession.addOutput(videoDataOutput)
        }
        if captureSession.canAddOutput(photoOutput) {
            self.captureSession.addOutput(photoOutput)
        }
        self.captureSession.commitConfiguration()
        self.videoDataOutput.connection(with: .video)?.videoOrientation = .portrait
        DispatchQueue.global(qos: .userInteractive).async { // High Priority Thread
            self.captureSession.startRunning()
            self.updateDeviceConfiguration(flash: BOFlashLight.torchMode)
        }
    }

    /// Update Flash Mode while scanning ID
    private func updateDeviceConfiguration(flash mode: AVCaptureDevice.TorchMode) {
        do {
            try device?.lockForConfiguration()
            /// Checking low light image optimization supported or not.
            if device?.isLowLightBoostSupported ?? false {
                device?.automaticallyEnablesLowLightBoostWhenAvailable = true
            }
            if device?.isTorchModeSupported(mode) ?? false {
                device?.torchMode = mode
            }
            /// To check camera continuosly capture good amount of light continuosly.
            let isCustomExposureEnabled = setting.enableCustomExposure
            let isCustomExposureSupported = device?.isExposureModeSupported(.custom) ?? false
            if isCustomExposureEnabled && isCustomExposureSupported {
                device?.setExposureModeCustom(duration: CMTimeMake(value: 1, timescale: 60),
                                              iso: 400, completionHandler: nil)
                setExposure(targetBias: 0.0)
            } else {
                if device?.isExposureModeSupported(.continuousAutoExposure) ?? false {
                    device?.exposureMode = .continuousAutoExposure
                }
            }
            /// To check object focusing supported or not.
            if device?.isFocusModeSupported(.continuousAutoFocus) ?? false {
                device?.focusMode = .continuousAutoFocus
            }
            device?.unlockForConfiguration()
        } catch let err {
            delegate?.failed(error: err)
        }
    }

}
