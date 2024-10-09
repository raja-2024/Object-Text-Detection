//
//  ViewController.swift
//  Object Text Detection
//
//  Created by Raja on 09/10/24.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var scanView: BOScanView!
    @IBOutlet weak var statusLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var setting = BOCameraSetting()
        setting.enableAutoDetection = true
        /// allowTextExtraction value is false then **func cameraView(didCapture image: UIImage?)** will return callback
        setting.allowTextExtraction = true
        let rect = scanView.addDetectionArea()
        scanView.startScan(cropRect: rect, setting: setting)
        scanView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scanView.restartScan()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        scanView.stopScan()
    }

    @IBAction func captureAction(_ sender: Any) {
        scanView.capturePhoto()
    }
    
}

// MARK: BOCameraViewDelegate
extension ViewController: BOCameraViewDelegate {
    
    func cameraView(didCapture image: UIImage?) {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ImageReviewController") as! ImageReviewController
        controller.capturedImage = image
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func cameraView(didCapture highlightedImage: UIImage, with info: [String: Any]) {
        debugPrint("\n Detected Text: \(info)")
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ImageReviewController") as! ImageReviewController
        controller.capturedImage = highlightedImage
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func cameraView(isLowLight: Bool, position: ObjectCaptureStatus) {
        statusLbl.text = isLowLight ? "Low Light" : position.rawValue
    }
    
}

extension UIView {

    /// Add Credit card view Inner and Outer layer
    /// - Parameters:
    ///  - cropAreaColor: To set the color of crop area background color
    ///  - bottomPadding: To over come any other UI overlap issue within overlay area.
    ///  - overlayColor: To set the background color except cropping area.
    func addDetectionArea(bottomPadding: CGFloat = 0,
                          cropAreaColor: UIColor = .clear,
                          overlayColor: UIColor = .black.withAlphaComponent(0.6)) -> CGRect {
        let outerpath = UIBezierPath(rect: bounds)
        
        let x: CGFloat = 24 //Padding leading and trailing
        let width = bounds.width - (2 * x)
        let aspectRatio = 0.65
        let height: CGFloat = width * aspectRatio
        let y: CGFloat = (bounds.height / 2) - (height / 2) - x - bottomPadding // For bottom padding
        let rect = CGRect(x: x, y: y, width: width, height: height)
        let innerpath = UIBezierPath(roundedRect: rect, cornerRadius: 16)
        outerpath.append(innerpath)
        outerpath.usesEvenOddFillRule = true
        // draw inner layer
        let ovalLayer = CAShapeLayer()
        ovalLayer.path = innerpath.cgPath
        ovalLayer.fillColor = cropAreaColor.cgColor
        // draw outer layer view
        let fillLayer = CAShapeLayer()
        fillLayer.path = outerpath.cgPath
        fillLayer.fillRule = .evenOdd
        fillLayer.fillColor = overlayColor.cgColor
        ovalLayer.accessibilityLabel = "bo_ovalLayer"
        if layer.sublayers == nil || layer.sublayers?.filter({$0.accessibilityLabel == "bo_ovalLayer"}).isEmpty == true {
            // add layers
            layer.addSublayer(fillLayer)
            layer.addSublayer(ovalLayer)
        }
        return rect
    }
}
