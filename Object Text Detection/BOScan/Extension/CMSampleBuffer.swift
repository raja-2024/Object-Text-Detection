//
//  CMSampleBuffer.swift
//
//
//  Created by Raja on 04/07/23.
//

import Foundation
import CoreMedia
import ImageIO
import AVFoundation

extension CMSampleBuffer {

    /// Return all info of the current video feed including camera information.
    var metaData: [String: Any]? {
        let dict = CMGetAttachment(self, key: kCGImagePropertyExifDictionary, attachmentModeOut: nil)
        return dict as? [String: Any]
    }

    /// Return whether surrounding has darker or not.
    /// Range of light is -8 to 8 where -8 is darkest and 8 is brightest
    var isLowLight: Bool {
        return brightness <= -3 // As per expriment
    }

    /// Return light value of current surrounding.
    var brightness: Double {
        return metaData?[kCGImagePropertyExifBrightnessValue as String] as? Double ?? 0
    }

}

extension AVCapturePhoto {

    /// Return full info of image with camera information
    var exifData: [String: Any]? {
        return metadata[kCGImagePropertyExifDictionary as String] as? [String: Any]
    }

    /// Checking whether the image looks darker or not.
    /// So we can increase the sharpness of the image later.
    var enableNightMode: Bool {
        return brightness <= 3 // As per expriment
    }

    /// Return light value of current image.
    var brightness: Double {
        return exifData?[kCGImagePropertyExifBrightnessValue as String] as? Double ?? 0
    }

}
