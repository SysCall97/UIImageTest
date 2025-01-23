//
//  extension.swift
//  UIImageTest
//
//  Created by Kazi Mashry on 24/1/25.
//

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
