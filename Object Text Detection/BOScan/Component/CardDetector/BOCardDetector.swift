//
//  BOCardDetection.swift
//
//
//  Created by Raja on 18/09/23.
//

import AVFoundation
import Vision

class BOCardDetector: BODocumentDetection {

    func detectDocument(in pixelBuffer: CVPixelBuffer,
        completionHandler: @escaping (
            VNRequestCompletionHandler
        )
    ) {
        do {
            let request = VNDetectRectanglesRequest(completionHandler: completionHandler)
            request.minimumAspectRatio = VNAspectRatio(0.3)
            request.maximumAspectRatio = VNAspectRatio(0.9)
            request.minimumSize = Float(0.3)
            request.maximumObservations = 1
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
            try imageRequestHandler.perform([request])
        } catch let err {
            debugPrint("\(BOScanLogs.logPrefix) \(err.localizedDescription)")
        }
    }
}
