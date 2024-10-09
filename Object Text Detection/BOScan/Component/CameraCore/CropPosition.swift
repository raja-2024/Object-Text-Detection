//
//  CropPosition.swift
//
//
//  Created by Raja on 04/07/23.
//

import Foundation

public enum ObjectCaptureStatus: String {
    case inner = "Too Close"
    case outer = "Align"
    case match = "Hold Tight"
    case tooFar = "Move Closer"
    var value: String {
        return self.rawValue
    }
}
