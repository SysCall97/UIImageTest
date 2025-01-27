//
//  MakeRoundVC.swift
//  UIImageTest
//
//  Created by Kazi Mashry on 1/27/25.
//

import UIKit

class MakeRoundVC: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var radiusSlider: UISlider!

    private var imageProcessor: RadiusImageProcessor!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let imageUrl = Bundle.main.url(forResource: "testImage", withExtension: "jpg") else { return }
        guard let image = UIImage(contentsOfFile: imageUrl.path) else { return }
        imageView.image = image

        self.imageProcessor = RadiusImageProcessor(image)
        self.imageProcessor.delegate = self
    }

    @IBAction func sliderUpdated(_ sender: Any) {
        self.imageProcessor.updateRadius(with: self.radiusSlider.value)
    }
}

extension MakeRoundVC: AnyImageProcessorDelegate {
    func configurationUpdated() {
        guard let image = imageProcessor.getProcessedImage() else { return }
        imageView.image = image
    }

}
