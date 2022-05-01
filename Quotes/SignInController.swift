//
//  SignInController.swift
//  Quotes
//
//  Created by Pizza Slice on 11/04/22.
//

import Foundation
import UIKit
import GoogleSignIn

final class SignInController: BaseController {
    
    // MARK: - PROPERTIES
    
    private var googleSignIn = GIDSignIn.sharedInstance
    
    private let image: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "image")
        image.contentMode = .scaleToFill
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    private let label: UILabel = {
        let label = UILabel()
        label.text = "Quotes"
        label.font = UIFont(name: "Zapfino", size: 60)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = buttonConfig()
        button.addTarget(self,
                         action: #selector(didTapped(_:)),
                         for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - LIFECYCLE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(image)
        view.addSubview(label)
        view.addSubview(button)
        
        setupConstraints()
    }
    
    // MARK: - SELECTOR
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: view.topAnchor),
            image.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            image.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            image.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            label.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            label.heightAnchor.constraint(equalToConstant: 150),
            label.widthAnchor.constraint(equalToConstant: 300),
            
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80),
            button.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            button.heightAnchor.constraint(equalToConstant: 50),
            button.widthAnchor.constraint(equalToConstant: 250),
        ])
    }
    
    private func buttonConfig() -> UIButton.Configuration {
        var config: UIButton.Configuration = .borderedProminent()
        var container = AttributeContainer()
        container.font = UIFont.boldSystemFont(ofSize: 18)
        config.attributedTitle = AttributedString("Sign In with Google",
                                                  attributes: container)
        config.image = UIImage(named: "google")
        config.baseBackgroundColor = .black
        config.baseForegroundColor = .white
        config.imagePadding = 8
        return config
    }
    
    @objc
    private func didTapped(_ sender: UIButton) {
#if targetEnvironment(macCatalyst)
        let controller = UINavigationController(rootViewController: CategoryController())
        controller.modalPresentationStyle = .fullScreen
        controller.modalTransitionStyle = .coverVertical
        let _ = self.present(controller, animated: true)
#else
        let googleConfig =  GIDConfiguration.init(clientID: CLIENT_ID)
        self.googleSignIn.signIn(with: googleConfig, presenting: self) { [weak self] _, error in
            if error == nil {
                let controller = UINavigationController(rootViewController: CategoryController())
                controller.modalPresentationStyle = .fullScreen
                controller.modalTransitionStyle = .coverVertical
                let _ = self?.present(controller, animated: true)
            }
        }
#endif
    }
    
}
