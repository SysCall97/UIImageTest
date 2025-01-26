//
//  ImageProcessor.swift
//  UIImageTest
//
//  Created by Kazi Mashry on 23/1/25.
//

import Foundation
import UIKit.UIImage

struct RGBADominance {
    let rDominance: Float
    let gDominance: Float
    let bDominance: Float
    let aDominance: Float
}

struct ImageConfiguration {
    let width: Int
    let height: Int
    var colorDominance: RGBADominance
    
    mutating func update(colorDominance: RGBADominance) {
        self.colorDominance = colorDominance
    }
}

protocol AnyImageProcessorDelegate: AnyObject {
    func configurationUpdated()
}

final class ImageProcessor {
    private let pixelBuffer: ByteBuffer?
    let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private var configuration: ImageConfiguration {
        didSet {
            print("Image configuration updated")
            self.delegate?.configurationUpdated()
        }
    }
    weak var delegate: AnyImageProcessorDelegate? = nil
    
    init(_ image: UIImage) {
        self.pixelBuffer = image.toByteBuffer()
        
        let colorDominance = RGBADominance(rDominance: 1.0,
                                           gDominance: 1.0,
                                           bDominance: 1.0,
                                           aDominance: 1.0)
        
        
        self.configuration = ImageConfiguration(
                                width: image.getWidth(),
                                height: image.getHeight(),
                                colorDominance: colorDominance)
    }
    
    func getProcessedImage() -> UIImage? {
        guard let pixelBuffer = pixelBuffer else { return nil }
        return pixelBuffer.toUIImageInGPU(with: configuration, ciContext: ciContext)
    }
    
}

extension ImageProcessor {
    func update(redDominance: Float) {
        let newDominance = RGBADominance(rDominance: redDominance,
                                         gDominance: configuration.colorDominance.gDominance,
                                         bDominance: configuration.colorDominance.bDominance,
                                         aDominance: configuration.colorDominance.aDominance)
        updateColorDominance(newDominance)
    }
    
    func update(greenDominance: Float) {
        let newDominance = RGBADominance(rDominance: configuration.colorDominance.rDominance,
                                         gDominance: greenDominance,
                                         bDominance: configuration.colorDominance.bDominance,
                                         aDominance: configuration.colorDominance.aDominance)
        updateColorDominance(newDominance)
    }
    
    func update(blueDominance: Float) {
        let newDominance = RGBADominance(rDominance: configuration.colorDominance.rDominance,
                                         gDominance: configuration.colorDominance.gDominance,
                                         bDominance: blueDominance,
                                         aDominance: configuration.colorDominance.aDominance)
        updateColorDominance(newDominance)
    }
    
    func update(alphaDominance: Float) {
        let newDominance = RGBADominance(rDominance: configuration.colorDominance.rDominance,
                                         gDominance: configuration.colorDominance.gDominance,
                                         bDominance: configuration.colorDominance.bDominance,
                                         aDominance: alphaDominance)
        updateColorDominance(newDominance)
    }

    private func updateColorDominance(_ dominance: RGBADominance) {
        self.configuration.update(colorDominance: dominance)
    }
}
