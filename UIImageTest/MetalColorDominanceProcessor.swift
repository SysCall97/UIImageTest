//
//  MetalColorDominanceProcessor.swift
//  UIImageTest
//
//  Created by Kazi Mashry on 1/26/25.
//

import UIKit
import Metal
import simd

class MetalColorDominanceProcessor {
    static let shared = MetalColorDominanceProcessor()

    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let defaultLibrary: MTLLibrary
    let pipelineState: MTLComputePipelineState

    private init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let defaultLibrary = device.makeDefaultLibrary(),
              let kernelFunction = defaultLibrary.makeFunction(name: "colorDominance") else {
            return nil
        }

        self.device = device
        self.commandQueue = commandQueue
        self.defaultLibrary = defaultLibrary
        self.pipelineState = try! device.makeComputePipelineState(function: kernelFunction)
    }

    func processImage(inputBuffer: ByteBuffer, configuration: ImageConfiguration) -> UIImage? {
        // Convert ByteBuffer to Metal Texture
        guard let inputTexture = createTexture(from: inputBuffer, configuration: configuration),
              let outputTexture = createEmptyTexture(width: configuration.width, height: configuration.height) else {
            return nil
        }

        // Perform Metal processing
        applyColorDominanceKernel(inputTexture: inputTexture, outputTexture: outputTexture, configuration: configuration)

        // Convert output Metal Texture to UIImage
        return convertToUIImage(from: outputTexture)
    }

    private func createTexture(from buffer: ByteBuffer, configuration: ImageConfiguration) -> MTLTexture? {
        guard let texture = self.createEmptyTexture(width: configuration.width, height: configuration.height) else { return nil }

        let region = MTLRegionMake2D(0, 0, configuration.width, configuration.height)
        texture.replace(region: region, mipmapLevel: 0, withBytes: buffer, bytesPerRow: configuration.width * 4)

        return texture
    }

    private func createEmptyTexture(width: Int, height: Int) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
        descriptor.usage = [.shaderRead, .shaderWrite]
        return device.makeTexture(descriptor: descriptor)
    }

    private func applyColorDominanceKernel(inputTexture: MTLTexture, outputTexture: MTLTexture, configuration: ImageConfiguration) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }

        computeEncoder.setComputePipelineState(pipelineState)
        computeEncoder.setTexture(inputTexture, index: 0)
        computeEncoder.setTexture(outputTexture, index: 1)

        var dominance = SIMD4<Float>(Float(configuration.colorDominance.rDominance),
                               Float(configuration.colorDominance.gDominance),
                               Float(configuration.colorDominance.bDominance),
                               Float(configuration.colorDominance.aDominance))
        computeEncoder.setBytes(&dominance, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)

        let width = pipelineState.threadExecutionWidth
        let height = pipelineState.maxTotalThreadsPerThreadgroup / width
        let threadgroupSize = MTLSize(width: width, height: height, depth: 1)
        let threadgroups = MTLSize(width: (inputTexture.width + width - 1) / width,
                                   height: (inputTexture.height + height - 1) / height,
                                   depth: 1)
        computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupSize)

        computeEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    private func convertToUIImage(from texture: MTLTexture) -> UIImage? {
        guard let ciImage = CIImage(mtlTexture: texture, options: nil) else {
            return nil
        }

        let flippedImage = ciImage.oriented(forExifOrientation: 4) // 4 is the EXIF orientation for 180-degree flip

        return UIImage(ciImage: flippedImage)
    }

}
