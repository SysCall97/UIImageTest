//
//  extension.swift
//  UIImageTest
//
//  Created by Kazi Mashry on 24/1/25.
//

//import Foundation
import UIKit.UIImage

extension UIImage {
    func toByteBuffer() -> ByteBuffer? {
        guard let cgImage = cgImage else { return nil }
        let width = self.getWidth()
        let height = self.getHeight()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        
        let bytePerPixel = 4 //RGBA
        let bytesPerRow = width * bytePerPixel
        let totalBytes = height * bytesPerRow
        
        var pixelBuffer: ByteBuffer = ByteBuffer(repeating: 0, count: totalBytes) // initialized with all 0s
        
        guard let context = CGContext(
            data: &pixelBuffer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return pixelBuffer
    }
    
    func getWidth() -> Int {
        return cgImage?.width ?? 0
    }
    
    func getHeight() -> Int {
        return cgImage?.height ?? 0
    }
}

extension ByteBuffer {
    func toUIImage(with configuration: ImageConfiguration) -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * configuration.width
        
        
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
            width: configuration.width,
            height: configuration.height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        
        guard let cgImage = context.makeImage() else { return nil }
        return UIImage(cgImage: cgImage)
        
    }
}
