//
//  ScreenCapturer.swift
//  Ambience
//
//  Created by Ayden Panhuyzen on 2017-12-30.
//  Copyright © 2017 Ayden Panhuyzen. All rights reserved.
//

import Cocoa
import CoreImage

class ScreenCapturer {
    static let shared = ScreenCapturer()
    private init() {}
    
    /// Take a screenshot and return it
    private func getScreenshot() -> CGImage? {
        return CGWindowListCreateImage(.infinite, .optionOnScreenOnly, kCGNullWindowID, [])
    }
    
    /// Take a screenshot and return its average colour
    private func getScreenAverageColour() -> NSColor? {
        guard let screenshot = getScreenshot() else { return nil }
        
        // Inspired by https://stackoverflow.com/a/32445855
        var bitmap = [UInt8](repeating: 0, count: 4)
        // Use CoreImage filter to create image with average colour
        let context = CIContext()
        let inputImage = CIImage(cgImage: screenshot)
        let extent = inputImage.extent
        let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
        guard let filter = CIFilter(name: "CIAreaAverage", withInputParameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: inputExtent]), let outputImage = filter.outputImage else { return nil }
        let outputExtent = outputImage.extent
        // Ensure image size is 1x1
        guard outputExtent.size.width == 1 && outputExtent.size.height == 1 else { return nil }
        
        // Render image to bitmap
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(origin: .zero, size: outputExtent.size), format: kCIFormatRGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        
        // Compute NSColor result
        return NSColor(red: CGFloat(bitmap[0] / 255), green: CGFloat(bitmap[1] / 255), blue: CGFloat(bitmap[2] / 255), alpha: CGFloat(bitmap[3] / 255))
    }
}
