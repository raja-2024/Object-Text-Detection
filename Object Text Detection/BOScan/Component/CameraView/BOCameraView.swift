//
//  BOCameraView.swift
//
//
//  Created by Raja on 21/09/23.
//

import UIKit
import CoreMedia
import AVFoundation

/// It will just add a camera preview layer and start preview live objects.
/// This should be used in case of all manual process of capturing images from camera.
public class BOCameraView: UIView, BOCameraOutputDelegate {

    /// Dependencies
    var camera: BOCameraObject?
    var setting: BOCameraSetting!
    var croppedRect: CGRect = .zero
    var isManuallyCaptured = false // To capture image on any manual action
    var isDetectionEnabled = true // To disable objecte detection until image captured.
    /// It will add camera preview layer at 0th index on view's layer to detect card with in given cropping area.
    /// - Parameters:
    ///  - cropRect: Need co-ordinate to show and crop the image.
    ///  - config: To set the color attributes of overlay and cropping area.
    ///  - setting: To set camera specific setting.
    public func startScan(cropRect: CGRect,
                          setting: BOCameraSetting = BOCameraSetting()) {
        if camera == nil {
            self.croppedRect = cropRect
            self.setting = setting
            self.camera = BOCamera(with: .back, setting: setting)
            self.camera?.delegate = self
            self.camera?.start(over: self)
        } else {
            restartScan()
        }
    }

    /// This method restart the whole process of camera. Call this method when you get the captured image.
    public func restartScan() {
        isDetectionEnabled = true
        camera?.restart()
    }

    /// This method will capture the current picture in the cropping area immediately.
    public func capturePhoto() {
        if !isManuallyCaptured {
            isManuallyCaptured = true
            camera?.capturePhoto()
        }
    }

    /// This method will change the flash mode and restart the camera preview.
    ///  You can use it on UIButton click event to set the current state of flash.
    ///  - Parameters
    ///   - mode: Current Flash mode
    public func changeFlash(mode: AVCaptureDevice.TorchMode?) {
        camera?.changeFlash(mode: mode)
    }

    /// This method will stop the flash immediately.
    public func stopFlash() {
        camera?.stopFlash()
    }

    /// It will stop capturing feed from camera. Call this method after you get your desired cropped image.
    public func stopScan() {
        isDetectionEnabled = false
        camera?.stop()
    }

    /// This is camera's delegate function that continuously calling to show live preview from camera.
    public func videoOutput(pixelBuffer: CVPixelBuffer,
                     sampleBuffer: CMSampleBuffer,
                     previewlayer: AVCaptureVideoPreviewLayer,
                            device: AVCaptureDevice?, queue: DispatchQueue) {

    }

    /// This function should be called when image is captured.
    public func photoOutput(output: AVCapturePhoto, previewlayer: AVCaptureVideoPreviewLayer) -> UIImage? {
        let data = output.fileDataRepresentation()
        if let data = data, let image = UIImage(data: data)?.crop(on: previewlayer, with: croppedRect) {
            return image
        } else {
            failed(error: BOCameraError.invalidImageData)
            return nil
        }
    }

    /// This function called when any error throw in between starting camera preview to capturing image.
    func failed(error: Error) {
        debugPrint("\(BOScanLogs.logPrefix) \(error.localizedDescription)")
    }
}
