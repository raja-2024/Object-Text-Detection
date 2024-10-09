//
//  File.swift
//  
//
//  Created by Mohd Tahir on 13/06/24.
//

import Vision

public protocol BODocumentDetection {

    func detectDocument(
        in pixelBuffer: CVPixelBuffer,
        completionHandler: @escaping (
            VNRequestCompletionHandler
        )
    )
}
