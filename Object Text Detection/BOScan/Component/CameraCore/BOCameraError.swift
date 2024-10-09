//
//  File.swift
//
//
//  Created by Raja on 12/09/23.
//

import Foundation

/// Custom error while starting or capturing image from camera.
enum BOCameraError: Error {
    case cameraNotFound
    case imageBufferNotFound
    case invalidImageData

}

/// Custom error while detecting card  from camera.
enum BOCardReaderError: Error {
    case objectNotFound
}
