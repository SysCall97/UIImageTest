//
//  RadiusImageProcessor.swift
//  UIImageTest
//
//  Created by Kazi Mashry on 1/27/25.
//

import Foundation
import CoreImage
import UIKit

struct Circle {
    let size: ImageSize
    var radius: Float
    let center: CGPoint

    mutating func update(radius: Float) {
        self.radius = radius
    }
}

final class RadiusImageProcessor {
    private let pixelBuffer: ByteBuffer?
    let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    let radius: Float
    private var configuration: Circle {
        didSet {
            print("Image configuration updated")
            self.delegate?.configurationUpdated()
        }
    }
    weak var delegate: AnyImageProcessorDelegate? = nil

    init(_ image: UIImage) {
        self.pixelBuffer = image.toByteBuffer()
        let center = CGPointMake(image.size.width / 2, image.size.height / 2)
        self.radius = Float(min(image.size.width, image.size.height) / 2)

        self.configuration = Circle(size: ImageSize(width: image.getWidth(), height: image.getHeight()), radius: radius, center: center)
    }

    func getProcessedImage() -> UIImage? {
        guard let pixelBuffer = pixelBuffer else { return nil }
        return pixelBuffer.toCircularUIImageInGPUWithMetal(with: configuration)
    }

    func updateRadius(with multiplier: Float) {
        let radius: Float = self.radius * multiplier
        configuration.update(radius: radius)
    }
}
