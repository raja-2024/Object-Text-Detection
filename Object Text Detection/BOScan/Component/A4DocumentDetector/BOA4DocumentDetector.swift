//
//  File.swift
//  
//
//  Created by Mohd Tahir on 13/06/24.
//

import Vision

class BOA4DocumentDetector: BODocumentDetection {

    func detectDocument(in pixelBuffer: CVPixelBuffer,
        completionHandler: @escaping (
            VNRequestCompletionHandler
        )
    ) {
        do {
            let request = VNDetectRectanglesRequest(completionHandler: completionHandler)
            // A4 Document Aspect Ratio - 1.4 & 1.44
            request.minimumAspectRatio = VNAspectRatio(0.70)
            request.maximumAspectRatio = VNAspectRatio(0.72)
            request.minimumSize = Float(0.3)
            request.maximumObservations = 1
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
            try imageRequestHandler.perform([request])
        } catch let err {
            debugPrint("\(BOScanLogs.logPrefix) \(err.localizedDescription)")
        }
    }
}
