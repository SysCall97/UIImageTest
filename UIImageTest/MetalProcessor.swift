//
//  MetalProcessor.swift
//  UIImageTest
//
//  Created by Kazi Mashry on 1/26/25.
//

import UIKit
import Metal
import simd

class MetalProcessor {
    static let shared = MetalProcessor()

    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let defaultLibrary: MTLLibrary
    let colorDominancePipelineState: MTLComputePipelineState
    let circularImagePipelineState: MTLComputePipelineState
    let previewImagePipelineState: MTLComputePipelineState

    private init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let defaultLibrary = device.makeDefaultLibrary(),
              let colorDominanceKernelFunction = defaultLibrary.makeFunction(name: "colorDominance"),
              let circularImageKernelFunction = defaultLibrary.makeFunction(name: "circularImage"),
              let previewImageKernelFunction = defaultLibrary.makeFunction(name: "previewImage") else {
            return nil
        }

        self.device = device
        self.commandQueue = commandQueue
        self.defaultLibrary = defaultLibrary
        self.colorDominancePipelineState = try! device.makeComputePipelineState(function: colorDominanceKernelFunction)
        self.circularImagePipelineState = try! device.makeComputePipelineState(function: circularImageKernelFunction)
        self.previewImagePipelineState = try! device.makeComputePipelineState(function: previewImageKernelFunction)
    }

    private func createTexture(from buffer: ByteBuffer, size: ImageSize) -> MTLTexture? {
        guard let texture = self.createEmptyTexture(width: size.width, height: size.height) else { return nil }

        let region = MTLRegionMake2D(0, 0, size.width, size.height)
        texture.replace(region: region, mipmapLevel: 0, withBytes: buffer, bytesPerRow: size.width * 4)

        return texture
    }

    private func createEmptyTexture(width: Int, height: Int) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
        descriptor.usage = [.shaderRead, .shaderWrite]
        return device.makeTexture(descriptor: descriptor)
    }

    private func convertToUIImage(from texture: MTLTexture) -> UIImage? {
        guard let ciImage = CIImage(mtlTexture: texture, options: nil) else {
            return nil
        }

        let flippedImage = ciImage.oriented(forExifOrientation: 4)

        let image = UIImage(ciImage: flippedImage)

        return image
    }

}

// MARK: Public APIs
extension MetalProcessor {
    func processImage(inputBuffer: ByteBuffer, configuration: ImageConfiguration) -> UIImage? {
        // Convert ByteBuffer to Metal Texture
        guard let inputTexture = createTexture(from: inputBuffer, size: configuration.size),
              let outputTexture = createEmptyTexture(width: configuration.size.width, height: configuration.size.height) else {
            return nil
        }

        // Perform Metal processing
        applyColorDominanceKernel(inputTexture: inputTexture, outputTexture: outputTexture, configuration: configuration)

        // Convert output Metal Texture to UIImage
        return convertToUIImage(from: outputTexture)
    }

    func processCircularImage(inputBuffer: ByteBuffer, configuration: Circle) -> UIImage? {
        guard let inputTexture = createTexture(from: inputBuffer, size: configuration.size),
              let outputTexture = createEmptyTexture(width: configuration.size.width, height: configuration.size.height) else {
            return nil
        }

        applyCircularKernel(inputTexture: inputTexture, outputTexture: outputTexture, configuration: configuration)
        return convertToUIImage(from: outputTexture)
    }

    func processPreviewImage(inputBuffer: ByteBuffer, configuration: AreaConfiguration) -> UIImage? {
        guard let inputTexture = createTexture(from: inputBuffer, size: configuration.size),
              let outputTexture = createEmptyTexture(width: configuration.previewImageSize.width, height: configuration.previewImageSize.height) else {
            return nil
        }

        print(configuration.bottomRight.x - configuration.topLeft.x)
        print(configuration.previewImageSize.width)

        print(configuration.topLeft.y - configuration.bottomRight.y)
        print(configuration.previewImageSize.height)

        
        applyPreviewKernel(inputTexture: inputTexture, outputTexture: outputTexture, configuration: configuration)
        return convertToUIImage(from: outputTexture)
    }
}

extension MetalProcessor {
    private func applyColorDominanceKernel(inputTexture: MTLTexture, outputTexture: MTLTexture, configuration: ImageConfiguration) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }

        computeEncoder.setComputePipelineState(colorDominancePipelineState)
        computeEncoder.setTexture(inputTexture, index: 0)
        computeEncoder.setTexture(outputTexture, index: 1)

        var dominance = SIMD4<Float>(Float(configuration.colorDominance.rDominance),
                               Float(configuration.colorDominance.gDominance),
                               Float(configuration.colorDominance.bDominance),
                               Float(configuration.colorDominance.aDominance))
        computeEncoder.setBytes(&dominance, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)

        let width = colorDominancePipelineState.threadExecutionWidth
        let height = colorDominancePipelineState.maxTotalThreadsPerThreadgroup / width
        let threadGroupSize = MTLSize(width: width, height: height, depth: 1)
        let threadGroups = MTLSize(width: (inputTexture.width + width - 1) / width,
                                   height: (inputTexture.height + height - 1) / height,
                                   depth: 1)
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)

        computeEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    private func applyCircularKernel(inputTexture: MTLTexture, outputTexture: MTLTexture, configuration: Circle) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }

        let cx = Float(configuration.center.x)
        let cy = Float(configuration.center.y)
        let rad = configuration.radius

        var boundary = SIMD3<Float>(cx, cy, rad)
        computeEncoder.setComputePipelineState(circularImagePipelineState)
        computeEncoder.setTexture(inputTexture, index: 0)
        computeEncoder.setTexture(outputTexture, index: 1)
        computeEncoder.setBytes(&boundary, length: MemoryLayout<SIMD3<Float>>.stride, index: 0)


        let width = colorDominancePipelineState.threadExecutionWidth
        let height = colorDominancePipelineState.maxTotalThreadsPerThreadgroup / width
        let threadGroupSize = MTLSize(width: width, height: height, depth: 1)
        let threadGroups = MTLSize(width: (inputTexture.width + width - 1) / width,
                                   height: (inputTexture.height + height - 1) / height,
                                   depth: 1)
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)

        computeEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

    }

    private func applyPreviewKernel(inputTexture: MTLTexture, outputTexture: MTLTexture, configuration: AreaConfiguration) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }

        let topLeft = configuration.topLeft
        let bottomRight = configuration.bottomRight

        print(topLeft)
        print(bottomRight)

        let lowerX: Float = Float(topLeft.x)
        let lowerY: Float = Float(topLeft.y)
        var boundary = SIMD2<Float>(lowerX, lowerY)

        computeEncoder.setComputePipelineState(previewImagePipelineState)
        computeEncoder.setTexture(inputTexture, index: 0)
        computeEncoder.setTexture(outputTexture, index: 1)
        computeEncoder.setBytes(&boundary, length: MemoryLayout<SIMD2<Float>>.stride, index: 0)


        let width = colorDominancePipelineState.threadExecutionWidth
        let height = colorDominancePipelineState.maxTotalThreadsPerThreadgroup / width
        let threadGroupSize = MTLSize(width: width, height: height, depth: 1)
        let threadGroups = MTLSize(width: (inputTexture.width + width - 1) / width,
                                   height: (inputTexture.height + height - 1) / height,
                                   depth: 1)
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)

        computeEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}
