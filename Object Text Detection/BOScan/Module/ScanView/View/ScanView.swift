//
//  ScanView.swift
//
//  Created by Raja on 18/09/23.
//

import UIKit
import AVFoundation
import Vision

/**
 It will add a camera preview layer and start preview live objects with detection constraints.
 It will auto capture image when object matching condition full fill.
 * Matching Condition should be confirm of **BOScanViewDelegate** delegate.
 * ** Delegates Methods should be confirmed **
 # Code
 ```
 func cameraView(cropRect: cropRect, detectedRect: bounds) -> CropPostion
 func cameraView(didCapture image: UIImage)
 ```
 when this function return .match it will automaticlly capture the image within cropping area.

 You can add your detector - ex
 - BOCardDetector: BODocumentDetection
 - BOA4DocumentDetector: BODocumentDetection
 ```
 func updateDocumentDetection(detection: BODocumentDetection)
 ```
 */
public class BOScanView: BOCameraView {

    /// To set the text label background color on detected card image.
    /// Default value is **RGBA(0, 0, 0, 0.3)**
    public var highlightedTextColor: UIColor = .green.withAlphaComponent(0.6)

    /// Set delegate to get callback of cropped **DL Image** .
    public weak var delegate: BOCameraViewDelegate?
    private var lastCardPosition: ObjectCaptureStatus = .outer
    private var isReadyToCrop = false
    private var sampleImageCount = 3

    /// Card Detector
    var documentDetector: BODocumentDetection = BOCardDetector()

    /// Text Detector
    lazy var textDetector: BOTextDetection = {
        return BOTextDetector()
    }()

    public func updateDocumentDetection(detection: BODocumentDetection) {

        self.documentDetector = detection
    }

    override public func videoOutput(pixelBuffer: CVPixelBuffer,
                              sampleBuffer: CMSampleBuffer,
                              previewlayer: AVCaptureVideoPreviewLayer,
                              device: AVCaptureDevice?, queue: DispatchQueue) {
        documentDetector.detectDocument(in: pixelBuffer, completionHandler: { [weak self] request, error in
            guard let weakSelf = self else { return }
            guard let rectangles = request.results as? [VNRectangleObservation] else { return }
            guard let rectangle = rectangles.first else {
                DispatchQueue.main.async {
                    let position = weakSelf.lastCardPosition
                    weakSelf.delegate?.cameraView(isLowLight: sampleBuffer.isLowLight, position: position)
                }
                return
            }
            let translatedY = -previewlayer.bounds.height
            let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: translatedY)
            let previewWidth = previewlayer.bounds.width
            let previewHeight = previewlayer.bounds.height
            let scale = CGAffineTransform.identity.scaledBy(x: previewWidth, y: previewHeight)
            let bounds = rectangle.boundingBox.applying(scale).applying(transform)
            let isAdjustingFocus = device?.isAdjustingFocus ?? true
            let isAdjustingExposure = device?.isAdjustingExposure ?? true
            let isCameraStable = !isAdjustingFocus && !isAdjustingExposure
            let position = bounds.cropPostion(in: weakSelf.croppedRect)
            // To restrict quick feedback object distance changes
            if position == weakSelf.lastCardPosition && position != .match {
                queue.suspend()
                DispatchQueue.main.asyncAfter(deadline: .now() + weakSelf.setting.distanceFeedbackDuration,
                                              execute: {
                    queue.resume()
                })
                return
            }
            DispatchQueue.main.async {
                weakSelf.lastCardPosition = position
                weakSelf.delegate?.cameraView(isLowLight: sampleBuffer.isLowLight, position: position)
            }
            weakSelf.isReadyToCrop = position == .match && !sampleBuffer.isLowLight && isCameraStable
            if weakSelf.isReadyToCrop && weakSelf.isDetectionEnabled {
                weakSelf.isDetectionEnabled = false
                DispatchQueue.main.asyncAfter(deadline: .now() + weakSelf.setting.processDuration, execute: {
                    if weakSelf.isReadyToCrop {
                        weakSelf.camera?.capturePhoto()
                    } else {
                        weakSelf.isDetectionEnabled = true
                    }
                })
            }
        })
    }

    override public func photoOutput(output: AVCapturePhoto, previewlayer: AVCaptureVideoPreviewLayer) -> UIImage? {
        if let captureImage = super.photoOutput(output: output, previewlayer: previewlayer) {
            var image: UIImage?
            /// Checking if the capture image is darker then we increase the sharpenss of the image.
            /// Intensity and Radius value is 1 because the greater the value more the images pixeleted.
            if output.enableNightMode {
                image = captureImage.sharpness(intensity: 1, radius: 1)
            } else {
                image = captureImage
            }
            if !isManuallyCaptured && setting.allowBlurDetection && image?.isBlur ?? false && sampleImageCount > 0 {
                sampleImageCount -= 1
                isDetectionEnabled = true
            } else {
                isDetectionEnabled = false
                sampleImageCount = 3
                stopFlash()
                AudioServicesPlaySystemSound(1108)
                isManuallyCaptured = false
                if setting.allowTextExtraction {
                    textExraction(of: image)
                } else {
                    delegate?.cameraView(didCapture: image)
                }
            }
            return image
        } else {
            delegate?.cameraView(didCapture: nil)
            return nil
        }
    }

    public override func restartScan() {
        lastCardPosition = .outer
        isManuallyCaptured = false
        super.restartScan()
    }

    override func failed(error: Error) {
        super.failed(error: error)
        delegate?.cameraView(didFailed: error)
    }
}

extension BOScanView {

    /// Text extraction from captured image
    private func textExraction(of image: UIImage?) {
        if let image = image {
            textDetector.detectText(uiImage: image, recognitionHandler: { [weak self ] recognizedTexts, error in
                let rects = recognizedTexts.map({$0.frame})
                let texts = recognizedTexts.map({$0.text})
                let paresedData = BOPaymentParser(detectedTexts: texts).parsedData
                let highlightColor: UIColor = self?.highlightedTextColor ?? .lightGray
                DispatchQueue.main.async {
                    if let cardImage = image.addDetectedTextBorder(rects: rects, highlightColor: highlightColor) {
                        self?.delegate?.cameraView(didCapture: cardImage, with: paresedData)
                    } else {
                        self?.failed(error: BOCameraError.invalidImageData)
                    }
                }
            })
        } else {
            self.failed(error: BOCameraError.invalidImageData)
        }
    }
}
