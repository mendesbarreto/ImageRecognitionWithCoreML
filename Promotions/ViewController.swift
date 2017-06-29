import UIKit
import Vision
import VideoToolbox

final class ViewController: UIViewController {
    
    typealias Prediction = (String, Double)
    
    let model = MobileNet()
    
    // MARK: - IBOutlets
    @IBOutlet weak var selectedImage: UIImageView!
    @IBOutlet weak var describeLabel: UILabel!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSelectedImage()
    }
    
    private func setupSelectedImage() {
        let image = UIImage(named: "cup")
        selectedImage.image = image
        predictUsingCoreML(image: image!)
    }
    
    fileprivate func show(results: [Prediction]) {
        var predictionsString: [String] = []
        for (i, prediction) in results.enumerated() {
            let percent = prediction.1 * 100
            let nameComplete = prediction.0
            var name: String = ""
            if (nameComplete.range(of: ",") != nil) {
                name = nameComplete.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: true).map(String.init).last!
            } else {
                name = nameComplete.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true).map(String.init).last!
            }
            predictionsString.append(String(format: "%d: %@ (%3.2f%%)", i + 1, name, percent))
        }
        describeLabel.text = predictionsString.joined(separator: "\n\n")
    }
    
    fileprivate func rankingPredictionsWith(top: Int, in prob: [String: Double]) -> [Prediction] {
        let rankingCount = top >= prob.count ? prob.count : top
        let orderedList = prob.map { keyPair in (keyPair.key, keyPair.value) }
            .sorted(by: { x, y -> Bool in x.1 > y.1 })
            .prefix(through: rankingCount - 1)
        return Array(orderedList)
    }
    
    fileprivate func predictUsingCoreML(image: UIImage) {
        if let pixelBuffer = image.pixelBuffer(width: 224, height: 224),
            let prediction = try? model.prediction(data: pixelBuffer) {
            let rankedList = rankingPredictionsWith(top: 5, in: prediction.prob)
            show(results: rankedList)
        }
    }
}

// MARK: - IBActions
extension ViewController {
    @IBAction func pickImage(_ sender: Any) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = .savedPhotosAlbum
        present(pickerController, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true)
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("couldn't load image from Photos")
        }
        selectedImage.image = image
        predictUsingCoreML(image: image)
    }
}

// MARK: - UINavigationControllerDelegate
extension ViewController: UINavigationControllerDelegate {
    
}

