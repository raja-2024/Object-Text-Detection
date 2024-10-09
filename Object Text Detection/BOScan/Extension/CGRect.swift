//
//  CGRect.swift
//
//
//  Created by Raja on 04/07/23.
//

import Foundation

extension CGRect {

    func cropPostion(in parent: CGRect) -> ObjectCaptureStatus {
        let detectedRect = self
        let leadingGap = (detectedRect.origin.x - parent.origin.x)
        let trailingGap = parent.width - (detectedRect.width + leadingGap)
        let minPadding: CGFloat = 20 // min space of detected card within cropping area
        let maxPadding: CGFloat = 70 // max space of detected card within cropping area
        let padding = leadingGap + trailingGap
        var result: ObjectCaptureStatus = .outer
        if parent.contains(detectedRect) {
            if padding >= minPadding && padding <= maxPadding {
                result = .match
            } else if padding < minPadding {
                result =  .inner
            } else if padding > maxPadding {
                result = .tooFar
            } else {
                result = .outer
            }
        } else {
            result = padding < minPadding ? .inner : padding > maxPadding ? .tooFar : .outer
        }
        return result
    }
}
