//
//  UIImage.swift
//
//
//  Created by Raja on 04/07/23.
//

import UIKit
import AVFoundation
import MetalPerformanceShaders
import MetalKit

extension UIImage {

    ///  Crop the image that lie with in cropping area
    ///   - Parameter cameraPreviewLayer: Cameara Preview Layer
    ///               rect: Cropping area.
    ///   - Returns cropped image
    ///
    func crop(on cameraPreviewLayer: AVCaptureVideoPreviewLayer, with rect: CGRect) -> UIImage? {
        let cgImage = self.cgImage ?? self.ciImage?.cgImage
        guard let cgImage = cgImage else { return nil }
        let padding: CGFloat = 10
        var increasedRect = rect
        increasedRect.origin.x = increasedRect.origin.x - padding
        increasedRect.origin.y = increasedRect.origin.y - padding
        increasedRect.size.width = increasedRect.size.width + 2 * padding
        increasedRect.size.height = increasedRect.size.height + 2 * padding
        let outputRect = cameraPreviewLayer.metadataOutputRectConverted(fromLayerRect: increasedRect)

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let cropRect = CGRect(x: (outputRect.origin.x * width),
                              y: (outputRect.origin.y * height),
                              width: (outputRect.size.width * width),
                              height: (outputRect.size.height * height))
        if let croppedCGImage = cgImage.cropping(to: cropRect) {
            return UIImage(cgImage: croppedCGImage, scale: scale, orientation: imageOrientation)
        }
        return nil
    }

    /// It apply CIUnsharpMask Filter and increases the sharpness of image.
    ///   - Parameter intensity: Sharness Intensity
    ///               radius : Radius of intensity.
    ///   - Returns filtered image
    ///
    func sharpness(intensity: Float, radius: Float) -> UIImage? {
        let beginImage = CIImage(image: self)
        let filter = CIFilter(name: "CIUnsharpMask")
        filter?.setValue(beginImage, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)
        filter?.setValue(intensity, forKey: kCIInputIntensityKey)
        if let filteredImage = filter?.outputImage, let cgImage = filteredImage.cgImage {
            return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
        }
        return nil
    }

    ///https://betterprogramming.pub/blur-detection-via-metal-on-ios-16dd02cb1558
    /// - Returns Image is blured or not.
    var isBlur: Bool {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let buffer = commandQueue.makeCommandBuffer() else {
            debugPrint("\(BOScanLogs.logPrefix) Metal is not supported on this device")
            return false
        }
        guard let ciImage = CIImage(image: self),
              let cgImage = ciImage.cgImage else {
            debugPrint("\(BOScanLogs.logPrefix) Failed to create CIImage")
            return false
        }
        let laplacian = MPSImageLaplacian(device: device)
        // Load the captured pixel buffer as a texture
        let meanAndVariance = MPSImageStatisticsMeanAndVariance(device: device)
        let textureLoader = MTKTextureLoader(device: device)
        do {
            // Create the destination texture for the laplacian transformation
            let sourceTexture = try textureLoader.newTexture(cgImage: cgImage, options: nil)
            let lapDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: sourceTexture.pixelFormat,
                                                                   width: sourceTexture.width,
                                                                   height: sourceTexture.height,
                                                                   mipmapped: false)
            let usage: MTLTextureUsage = [.shaderWrite,
                                          .shaderRead,
                                          .unknown,
                                          .renderTarget,
                                          .pixelFormatView]
            lapDesc.usage = usage
            if let lapTex = device.makeTexture(descriptor: lapDesc) {
                // Encode this as the first transformation to perform
                laplacian.encode(commandBuffer: buffer,
                                 sourceTexture: sourceTexture,
                                 destinationTexture: lapTex)
                // Create the destination texture for storing the variance.
                let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: sourceTexture.pixelFormat,
                                                                          width: 2,
                                                                          height: 1,
                                                                          mipmapped: false)
                descriptor.usage = usage
                // Encode this as the second transformation
                if let varianceTexture = device.makeTexture(descriptor: descriptor) {
                    // Run the command buffer on the GPU and wait for the results
                    meanAndVariance.encode(commandBuffer: buffer,
                                           sourceTexture: lapTex,
                                           destinationTexture: varianceTexture)
                    buffer.commit()
                    // The output will be just 2 pixels, one with the mean, the other the variance.
                    buffer.waitUntilCompleted()
                    var result = Int8()
                    let region = MTLRegionMake2D(0, 0, 2, 1)
                    varianceTexture.getBytes(&result, bytesPerRow: 1 * 2 * 4, from: region, mipmapLevel: 0)
                    let variance = result
                    // variance of 0, 1, or 2 would be too blurry
                    debugPrint("\(BOScanLogs.logPrefix) Image variance value is \(variance)")
                    return variance <= 3
                }
            }
        } catch let err {
            debugPrint("\(BOScanLogs.logPrefix) \(err.localizedDescription)")
        }
        return false
    }

    /// Convert UIImage to PixelBuffer Format
    var pixelBuffer: CVPixelBuffer? {
        /*
         Reference: https://itecnote.com/tecnote/swift-how-to-convert-a-uiimage-to-a-cvpixelbuffer/
         */
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(size.width),
                                         Int(size.height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess), let buffer = pixelBuffer else {
            return nil
        }
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        context?.translateBy(x: 0, y: size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        UIGraphicsPushContext(context!)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        return buffer
    }

    /// Return a new image by adding overlay on given rects
    ///  - Parameters -
    ///     - rects: Frames of the overlay
    ///     - highlightColor: To set the background color of recognized text.
    ///  - Returns -
    ///     - UIImage: Updated image with overlay drawed on it.
    func addDetectedTextBorder(rects: [CGRect], highlightColor: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: .zero)
        let currentContext = UIGraphicsGetCurrentContext()
        let color = highlightColor
        currentContext?.setFillColor(color.cgColor)
        currentContext?.fill(rects)
        guard let drawnImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        UIGraphicsEndImageContext()
        return drawnImage
    }

}

extension CIImage {

    /// Convert CIImage to CGImage
    var cgImage: CGImage? {
        let context = CIContext(options: nil)
        return context.createCGImage(self, from: extent)
    }
}
