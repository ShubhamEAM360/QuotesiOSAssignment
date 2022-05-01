//
//  TextRecognizeController.swift
//  Quotes
//
//  Created by Pizza Slice on 17/04/22.
//

import Foundation
import UIKit
import PhotosUI
import Vision

final class TextRecognizeController: BaseController {
    
    // MARK: - PROPERTIES
    
    public var completionHandler: ((String?) -> Void)?
    
    private let image: UIImageView = {
        let image = UIImageView()
        image.layer.borderWidth = 2
        image.layer.borderColor = UIColor.systemGreen.cgColor
        image.layer.masksToBounds = true
        image.layer.cornerRadius = 12
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    private lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = buttonConfig()
        button.addTarget(self,
                         action: #selector(pickPhotoHandler(_:)),
                         for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let text: UITextView = {
        let text = UITextView()
        text.textColor = .secondaryLabel
        text.font = .systemFont(ofSize: 14)
        text.backgroundColor = .secondarySystemBackground
        text.layer.masksToBounds = true
        text.layer.cornerRadius = 12
        text.translatesAutoresizingMaskIntoConstraints = false
        return text
    }()
    
    // MARK: - LIFECYCLE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        navigationItem.title = "Text Recognize"
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.tintColor = .label
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .save,
                                                            primaryAction: UIAction(handler: { [unowned self] _ in
            self.completionHandler?(text.text)
            let _ = navigationController?.popViewController(animated: true)
        }),
                                                            menu: .none)
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel,
                                                           primaryAction: UIAction(handler: { [unowned self] _ in
            let _ = self.navigationController?.popViewController(animated: true)
        }),
                                                           menu: .none)
        
        view.addSubview(image)
        view.addSubview(button)
        view.addSubview(text)
        setupConstraints()
    }
    
    // MARK: - SELECTOR
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            image.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 40),
            image.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -40),
            image.heightAnchor.constraint(equalToConstant: 300),
            
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.heightAnchor.constraint(equalToConstant: 50),
            button.widthAnchor.constraint(equalToConstant: 250),
            
            text.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 20),
            text.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            text.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            text.heightAnchor.constraint(equalToConstant: 200),
        ])
    }
    
    private func buttonConfig() -> UIButton.Configuration {
        var config: UIButton.Configuration = .tinted()
        var container = AttributeContainer()
        container.font = UIFont.boldSystemFont(ofSize: 18)
        config.attributedTitle = AttributedString("Pick Photo", attributes: container)
        config.baseBackgroundColor = .label
        config.baseForegroundColor = .label
        return config
    }
    
    // MARK: HANDLER
    @objc
    private func pickPhotoHandler(_ sender: UIButton) {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = PHPickerFilter.images
        
        let controller = PHPickerViewController(configuration: config)
        controller.delegate = self
        self.present(controller, animated: true, completion: nil)
    }
    
    // RECOGNIZE TEXT
    private func recognizeText(image: UIImage?) {
        guard let cgImage = image?.cgImage else { return }
        
        // HANDLER
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // REQUEST
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observation = request.results as? [VNRecognizedTextObservation], error == nil else {
                return
            }
            let text = observation.compactMap ({
                $0.topCandidates(1).first?.string
            }).joined(separator: " ")
            DispatchQueue.main.async {
                self?.text.text = text
            }
        }
        
        // PROCESS REQUEST
        do {
            try handler.perform([request])
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
}


// MARK: - EXTENSION

extension TextRecognizeController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        
        if let itemProvider = results.first?.itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
            let previousImage = image.image
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                DispatchQueue.main.async {
                    guard let self = self, let image = image as? UIImage, self.image.image == previousImage else { return }
                    self.image.image = image
                }
                let _ = self?.recognizeText(image: image as? UIImage)
            }
        }
    }
}
