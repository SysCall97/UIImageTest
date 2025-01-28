//
//  PreviewImageProcessor.swift
//  UIImageTest
//
//  Created by Kazi Mashry on 1/27/25.
//

import Foundation
import CoreImage
import UIKit


struct AreaConfiguration {
    let size: ImageSize
    let previewImageSize: ImageSize
    var topLeft: CGPoint
    var bottomRight: CGPoint

    mutating func update(topLeft: CGPoint, bottomRight: CGPoint) {
        self.topLeft = topLeft
        self.bottomRight = bottomRight
    }
}

final class PreviewImageProcessor {
    private let pixelBuffer: ByteBuffer?
    let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    let radius: Float
    private var configuration: AreaConfiguration {
        didSet {
            print("Image configuration updated")
            self.delegate?.configurationUpdated()
        }
    }
    weak var delegate: AnyImageProcessorDelegate? = nil

    init(_ image: UIImage, previewImageSize: ImageSize) {
        self.pixelBuffer = image.toByteBuffer()
        self.radius = Float(min(image.size.width, image.size.height) / 2)

        self.configuration = AreaConfiguration(size: ImageSize(width: image.getWidth(), height: image.getHeight()), previewImageSize: previewImageSize, topLeft: .zero, bottomRight: .zero)
    }

    func getProcessedImage() -> UIImage? {
        guard let pixelBuffer = pixelBuffer else { return nil }
        return pixelBuffer.toPreviewImageInGPUWithMetal(with: configuration)
    }

    func update(with topLeft: CGPoint, bottomRight: CGPoint) {
        configuration.update(topLeft: topLeft, bottomRight: bottomRight)
    }
}
