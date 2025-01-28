//
//  PanExpVC.swift
//  UIImageTest
//
//  Created by Kazi Mashry on 1/27/25.
//

import UIKit

class PanExpVC: UIViewController {

    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var imageView: UIImageView!

    private var imageProcessor: PreviewImageProcessor!
    private var width: CGFloat = 0
    private var height: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let imageUrl = Bundle.main.url(forResource: "testImage", withExtension: "jpg") else { return }
        guard let image = UIImage(contentsOfFile: imageUrl.path) else { return }
        imageView.image = image

        let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        self.imageView.addGestureRecognizer(gesture)

        self.imageProcessor = PreviewImageProcessor(image,
                                                    previewImageSize:
                                                        ImageSize(width: Int(self.previewImageView.bounds.width), height: Int(self.previewImageView.bounds.height)))
        self.imageProcessor.delegate = self

        if let originalImage = imageView.image {
            let originalSizeInPixels = CGSize(width: originalImage.size.width * originalImage.scale,
                                              height: originalImage.size.height * originalImage.scale)
            self.width = originalSizeInPixels.width
            self.height = originalSizeInPixels.height
        }
    }


    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .ended {
            self.previewImageView.image = nil
            return
        }
        let location = gesture.location(in: self.imageView)
        guard let loc1 = self.convertPointInImageViewToOriginalImageCoordinates(cx: location.x, cy: location.y) else { return }
        let cx = loc1.x
        let cy = loc1.y



        let topLeft: CGPoint = CGPoint(x: cx - (self.previewImageView.bounds.width / 2), y: cy - (self.previewImageView.bounds.height / 2))
        let bottomRight: CGPoint = CGPoint(x: cx + (self.previewImageView.bounds.width / 2), y: cy + (self.previewImageView.bounds.height / 2))

        self.imageProcessor.update(with: topLeft, bottomRight: bottomRight)

    }
}


extension PanExpVC: AnyImageProcessorDelegate {
    func configurationUpdated() {
        guard let image = imageProcessor.getProcessedImage() else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            previewImageView.image = image
        }
    }

    func convertPointInImageViewToOriginalImageCoordinates(cx: CGFloat, cy: CGFloat) -> CGPoint? {
        let originalSize = CGSize(width: self.width,
                                  height: self.height)

        // UIImageView size
        let imageViewSize = imageView.bounds.size

        // Get the content mode scaling
        let imageViewAspectRatio = imageViewSize.width / imageViewSize.height
        let imageAspectRatio = originalSize.width / originalSize.height

        var scaleX: CGFloat = 1.0
        var scaleY: CGFloat = 1.0
        var offsetX: CGFloat = 0.0
        var offsetY: CGFloat = 0.0

        switch imageView.contentMode {
        case .scaleAspectFit:
            // Aspect Fit: Image fits within the UIImageView while maintaining the aspect ratio
            if imageAspectRatio > imageViewAspectRatio {
                scaleX = imageViewSize.width / originalSize.width
                scaleY = scaleX
                offsetY = (imageViewSize.height - (originalSize.height * scaleY)) / 2.0
            } else {
                scaleY = imageViewSize.height / originalSize.height
                scaleX = scaleY
                offsetX = (imageViewSize.width - (originalSize.width * scaleX)) / 2.0
            }

        case .scaleAspectFill:
            // Aspect Fill: Image fills the UIImageView while maintaining the aspect ratio, may be clipped
            if imageAspectRatio > imageViewAspectRatio {
                scaleY = imageViewSize.height / originalSize.height
                scaleX = scaleY
                offsetX = (imageViewSize.width - (originalSize.width * scaleX)) / 2.0
            } else {
                scaleX = imageViewSize.width / originalSize.width
                scaleY = scaleX
                offsetY = (imageViewSize.height - (originalSize.height * scaleY)) / 2.0
            }

        default:
            // Handle other content modes if needed (e.g., .scaleToFill, .center)
            scaleX = imageViewSize.width / originalSize.width
            scaleY = imageViewSize.height / originalSize.height
        }

        // Translate cx, cy in UIImageView to the corresponding point in the original image
        let imageX = (cx - offsetX) / scaleX
        let imageY = (cy - offsetY) / scaleY

        // Ensure the point is within bounds
        let originalPoint = CGPoint(x: min(max(imageX, 0), originalSize.width),
                                    y: min(max(imageY, 0), originalSize.height))

        return originalPoint
    }


}
