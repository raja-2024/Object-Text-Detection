//
//  BOCameraProtocol.swift
//
//
//  Created by Raja on 12/09/23.
//

import UIKit
import AVFoundation

/// Returns callback of camera video live preview and photo capture.
 protocol BOCameraOutputDelegate: NSObject {
    func videoOutput(pixelBuffer: CVPixelBuffer,
                     sampleBuffer: CMSampleBuffer,
                     previewlayer: AVCaptureVideoPreviewLayer,
                     device: AVCaptureDevice?,
                     queue: DispatchQueue)
    func photoOutput(output: AVCapturePhoto, previewlayer: AVCaptureVideoPreviewLayer) -> UIImage?
    func failed(error: Error)
}

/// Basic guidelines to use camera
protocol BOCameraObject: NSObject {
    func start(over view: UIView)
    func restart()
    func stop()
    func capturePhoto()
    func changeFlash(mode: AVCaptureDevice.TorchMode?)
    func stopFlash()
    init(with cameraPostion: BOCameraPostion, setting: BOCameraSetting)
    var delegate: BOCameraOutputDelegate? { get set }
    var currentCameraType: AVCaptureDevice.DeviceType? { get }
    /// To set bias value which make image darker to lighter. Value should between -8 to 8.
    func setExposure(targetBias: Double)
}

public struct BOCameraSetting {
    public init() {}
    // To enable capturing process with lower shutter speed
    public var enableCustomExposure = false
    // To set the duration of capturing the card after detection
    public var processDuration: TimeInterval = 0
    // To enable live video caturing process, who is responsible for rectangle detection
    public var enableAutoDetection = true
    // To allow text extraction from captured image
    public var allowTextExtraction = false
    // To allow checking of blurriness in image while capturing
    public var allowBlurDetection = true
    // To allow object distance feedback changes duration
    public var distanceFeedbackDuration: TimeInterval = 0.5
    // To priorities camera lens while detecting DL
    public var cameraLensPriortization: BOCameraLensType = .main
}

public enum BOCameraLensType {
    case main
    case ultraWide
}
