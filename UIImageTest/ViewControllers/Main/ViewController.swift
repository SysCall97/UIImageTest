//
//  ViewController.swift
//  UIImageTest
//
//  Created by Kazi Mashry on 23/1/25.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    private var imageProcessor: ImageProcessor!
    @IBOutlet weak var rSlider: UISlider!
    @IBOutlet weak var gSlider: UISlider!
    @IBOutlet weak var bSlider: UISlider!
    @IBOutlet weak var aSlider: UISlider!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        guard let imageUrl = Bundle.main.url(forResource: "image", withExtension: "jpeg") else { return }
        guard let image = UIImage(contentsOfFile: imageUrl.path) else { return }
        imageView.image = image
        
        
        self.imageProcessor = ImageProcessor(image)
        self.imageProcessor.delegate = self
    }
    
    @IBAction func redSliderUpdated(_ sender: Any) {
        self.imageProcessor.update(redDominance: rSlider.value)
    }
    
    @IBAction func greenSliderUpdated(_ sender: Any) {
        self.imageProcessor.update(greenDominance: gSlider.value)
    }
    
    @IBAction func blueSliderUpdated(_ sender: Any) {
        self.imageProcessor.update(blueDominance: bSlider.value)
    }
    
    @IBAction func alphaSliderUpdated(_ sender: Any) {
        self.imageProcessor.update(alphaDominance: aSlider.value)
    }
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "MakeRoundVC", bundle: .main)
        let congratulationsVC = storyboard.instantiateViewController(withIdentifier: "MakeRoundVC") as! MakeRoundVC
        congratulationsVC.modalPresentationStyle = .overFullScreen
        self.present(congratulationsVC, animated: true)
    }

    @IBAction func panExpButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "PanExpVC", bundle: .main)
        let congratulationsVC = storyboard.instantiateViewController(withIdentifier: "PanExpVC") as! PanExpVC
        congratulationsVC.modalPresentationStyle = .overFullScreen
        self.present(congratulationsVC, animated: true)
    }
    
}

extension ViewController: AnyImageProcessorDelegate {
    func configurationUpdated() {
        guard let image = imageProcessor.getProcessedImage() else { return }
        imageView.image = image
    }
    
    
}
