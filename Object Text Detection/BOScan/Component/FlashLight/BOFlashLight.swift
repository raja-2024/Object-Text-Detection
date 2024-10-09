//
//  BOFlashLight.swift
//
//
//  Created by Raja on 10/07/23.
//

import AVFoundation
import UIKit

/// To set camera flash mode while scanning ID.
public class BOFlashLight {

    /// To set the flash mode.
    /// Defalut value is **OFF**
    public static var torchMode: AVCaptureDevice.TorchMode {
        set {
            flashMode = String(newValue.rawValue)
        } get {
            let value = Int(flashMode) ?? 0
            return AVCaptureDevice.TorchMode(rawValue: value) ?? .off
        }
    }

    public static func toggle() {
        let status = torchMode
        if status == .off {
            torchMode = .on
        } else if status == .on {
            torchMode = .auto
        } else {
            torchMode = .off
        }
        toggleTorch(mode: torchMode)
    }

    private static func toggleTorch(mode: AVCaptureDevice.TorchMode) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                device.torchMode = mode
                device.unlockForConfiguration()
            } catch {
                print("\(BOScanLogs.logPrefix) Torch could not be used")
            }
        } else {
            print("\(BOScanLogs.logPrefix) Torch is not available")
        }
    }
}

extension BOFlashLight {

    /// File Url that contains data.
    private static var fileURL: URL? {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return directory?.appendingPathComponent("flashMode.txt")
    }

    /// Writing and Reading Value From a text file of the document directory.
    private static var flashMode: String {
        get {
            if let url = fileURL {
                let value = try? String(contentsOf: url)
                return  value ?? "0"
            } else {
                return "0"
            }
        } set {
            if let url = fileURL {
                try? newValue.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}
