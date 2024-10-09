//
//  BOCameraViewDelegate.swift
//
//
//  Created by Raja on 21/09/23.
//

import UIKit

public protocol BOCameraViewDelegate: AnyObject {
    /// It will set the camera position for detection of object.
    var cameraPosition: BOCameraPostion { get }
    ///  Through this delegate method you will get  either highlighted text image or simply cropped image.
    func cameraView(didCapture image: UIImage?)
    /// Through this delegate method you will get highlighted texts or recognized texts.
    func cameraView(didCapture highlightedImage: UIImage, with info: [String: Any])
    /// Exception Handling from starting the camera preview to captured image process.
    func cameraView(didFailed error: Error)
    /// It will give the call back of card position and environment light condition
    func cameraView(isLowLight: Bool, position: ObjectCaptureStatus)
}

public extension BOCameraViewDelegate {

    var cameraPosition: BOCameraPostion {
        .back
    }

    func cameraView(didCapture image: UIImage?) { }

    func cameraView(didFailed error: Error) { }

    func cameraView(isLowLight: Bool, position: ObjectCaptureStatus) { }

    func cameraView(didCapture highlightedImage: UIImage, with info: [String: Any]) {}
}

