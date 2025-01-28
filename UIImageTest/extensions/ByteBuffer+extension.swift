//
//  ByteBuffer+extension.swift
//  UIImageTest
//
//  Created by Kazi Mashry on 24/1/25.
//

import CoreImage
import UIKit

public typealias ByteBuffer = [UInt8]

extension ByteBuffer {
    func toUIImage(with configuration: ImageConfiguration) -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * configuration.size.width

        
        var pixelBuffer: ByteBuffer = []
        let colorDominance: RGBADominance = configuration.colorDominance
        
        for i in stride(from: 0, to: self.count, by: 4) {
            // RGBA values
            let r = UInt8(colorDominance.rDominance * Float(self[i]))
            let g = UInt8(colorDominance.gDominance * Float(self[i + 1]))
            let b = UInt8(colorDominance.bDominance * Float(self[i + 2]))
            let a = UInt8(colorDominance.aDominance * Float(self[i + 3]))
            
            pixelBuffer.append(contentsOf: [r, g, b, a])
        }
        
        guard let context = CGContext(
            data: UnsafeMutableRawPointer(mutating: pixelBuffer),
            width: configuration.size.width,
            height: configuration.size.height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        
        guard let cgImage = context.makeImage() else { return nil }
        return UIImage(cgImage: cgImage)
        
    }
}

extension ByteBuffer {
    func toUIImageInGPU(with configuration: ImageConfiguration, ciContext: CIContext) -> UIImage? {
        let colorDominance = configuration.colorDominance

        guard let dataProvider = CGDataProvider(data: Data(self) as CFData),
              let cgImage = CGImage(
                width: configuration.size.width,
                height: configuration.size.height,
                bitsPerComponent: 8,
                bitsPerPixel: 8 * 4,
                bytesPerRow: 4 * configuration.size.width,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: dataProvider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else {
            return nil
        }

        let ciImage = CIImage(cgImage: cgImage)

        let dominanceVector = CIVector(x: CGFloat(colorDominance.rDominance),
                                       y: CGFloat(colorDominance.gDominance),
                                       z: CGFloat(colorDominance.bDominance),
                                       w: CGFloat(colorDominance.aDominance))
        let processedImage = ColorDominanceFilter.kernel.apply(
            extent: ciImage.extent,
            arguments: [ciImage, dominanceVector]
        )

        if let outputImage = processedImage,
           let outputCGImage = ciContext.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: outputCGImage)
        }

        return nil
    }

    func toUIImageInGPUWithMetal(with configuration: ImageConfiguration) -> UIImage? {
        return MetalProcessor.shared?.processImage(inputBuffer: self, configuration: configuration)
    }

    func toCircularUIImageInGPUWithMetal(with configuration: Circle) -> UIImage? {
        return MetalProcessor.shared?.processCircularImage(inputBuffer: self, configuration: configuration)
    }

    func toPreviewImageInGPUWithMetal(with configuration: AreaConfiguration) -> UIImage? {
        return MetalProcessor.shared?.processPreviewImage(inputBuffer: self, configuration: configuration)
    }
}



class ColorDominanceFilter {
    static let kernel = CIColorKernel(source: """
    kernel vec4 colorDominance(__sample image, vec4 dominance) {
        return vec4(
            image.r * dominance.r,
            image.g * dominance.g,
            image.b * dominance.b,
            image.a * dominance.a
        );
    }
    """)!
}
