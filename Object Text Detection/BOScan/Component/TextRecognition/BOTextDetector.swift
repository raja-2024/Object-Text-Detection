//
//  BOTextRecognizer.swift
//
//  Created by Raja on 18/09/23.
//

import UIKit
import Vision

public protocol BOTextDetection {
    func detectText(uiImage: UIImage, recognitionHandler: @escaping (([BORecognizedText], Error?) -> Void))
    func detectText(cvPixelBuffer: CVPixelBuffer, recognitionHandler: @escaping (([BORecognizedText], Error?) -> Void))
}

/// Recognize all texts of a specific image.
class BOTextDetector: BOTextDetection {

    /// Start recognition of texts.
    /// - Parameters: cvPixelBuffer -> Image on which text should be recognized.
    /// - Returns: recognitionHandler with recongized texts as **[String]**
    func detectText(cvPixelBuffer: CVPixelBuffer, recognitionHandler: @escaping (([BORecognizedText], Error?) -> Void)) {
        let width = CVPixelBufferGetWidth(cvPixelBuffer)
        let height = CVPixelBufferGetHeight(cvPixelBuffer)
        let size = CGSize(width: width, height: height)
        let request = VNRecognizeTextRequest { [weak self] request, error in
            if error == nil {
                let results = request.results as? [VNRecognizedTextObservation]
                guard let observations = results else { return }

                let text = self?.recognizedTexts(of: size, observations: observations) ?? []
                recognitionHandler(text, nil)
            } else {
                recognitionHandler([], error)
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let languages = ["en", "en-AU", "en-CA", "en-US", "en-GB"]
        request.recognitionLanguages = languages
        let handler = VNImageRequestHandler(cvPixelBuffer: cvPixelBuffer)
        do {
            try handler.perform([request])
        } catch let err {
            recognitionHandler([], err)
        }
    }

    /// Start recognition of texts.
    /// - Parameters: uiImage -> Image on which text should be recognized.
    /// - Returns: recognitionHandler with recongized texts as **[String]**
     func detectText(uiImage: UIImage, recognitionHandler: @escaping (([BORecognizedText], Error?) -> Void)) {
         if let buffer = uiImage.pixelBuffer {
             detectText(cvPixelBuffer: buffer, recognitionHandler: recognitionHandler)
         } else {
             recognitionHandler([], NSError(domain: "domain.com", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Converting UIImage to CVPixelBuffer failed"
             ]))
         }
    }
}

extension BOTextDetector {

    /// Convert TextObservation to Text along with its dimension.
    ///  - Parameters : size: size of the container or image.
    ///                observations: Recognized text on the image
    ///  - Returns : Array of BORecognizedText that contains text and its dimension
    private func recognizedTexts(of size: CGSize, observations: [VNRecognizedTextObservation]) -> [BORecognizedText] {
        let recognizedTexts: [BORecognizedText] = observations.compactMap { observation in
            // Find the top observation.
            guard let candidate = observation.topCandidates(1).first else {
                return BORecognizedText(text: "", frame: .zero)
            }
            let rect = convert(boundingBox: observation.boundingBox,
                               to: CGRect(origin: .zero, size: size))
            return BORecognizedText(text: candidate.string, frame: rect)
        }
        return recognizedTexts
    }

    /// Convert Vision coordinates to pixel coordinates within image.
    ///
    /// Adapted from `boundingBox` method from
    /// [Detecting Objects in Still Images](https://developer.apple.com/documentation/vision/detecting_objects_in_still_images).
    /// This flips the y-axis.
    ///
    /// - Parameters:
    ///   - boundingBox: The bounding box returned by Vision framework.
    ///   - bounds: The bounds within the image (in pixels, not points).
    /// - Returns: The bounding box in pixel coordinates, flipped vertically so 0,0 is in the upper left corner
    private func convert(boundingBox: CGRect, to bounds: CGRect) -> CGRect {
        let imageWidth = bounds.width
        let imageHeight = bounds.height

        // Begin with input rect.
        var rect = boundingBox

        // Reposition origin.
        rect.origin.x *= imageWidth
        rect.origin.x += bounds.minX
        rect.origin.y = (1 - rect.maxY) * imageHeight + bounds.minY

        // Rescale normalized coordinates.
        rect.size.width *= imageWidth
        rect.size.height *= imageHeight

        return rect
    }
}
