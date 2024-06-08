//
//  OnboardContentVC.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 01.06.2024.
//

import UIKit

// MARK: - UIViewController

final class OnboardContentViewController: UIViewController {
    weak var delegate: ContentViewControllerDelegate?
    var descriptionText: String?
    var backgroundImage: UIImage?
    
    // MARK: - UiElements
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.boldSystemFont(ofSize: 32)
        label.tintColor = .ypBlackDay
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var button: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("onboardingButton", comment: "onboardingButton"), for: .normal)
        button.layer.cornerRadius = 16
        button.backgroundColor = .ypBlackDay
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        return button
    }()
    
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configViews()
        configConstraints()
    }
    
    // MARK: - Actions
    
    @objc func didTapButton() {
        delegate?.didTapButton()
    }
    
    // MARK: - Private methods
    
    private func configViews() {
        label.text = descriptionText
        backgroundImageView.image = backgroundImage
        view.addSubview(backgroundImageView)
        view.addSubview(label)
        view.addSubview(button)
    }
    
    private func configConstraints() {
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            label.heightAnchor.constraint(equalToConstant: 76),
            label.widthAnchor.constraint(equalToConstant: 343),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -304),
            
            button.heightAnchor.constraint(equalToConstant: 60),
            button.widthAnchor.constraint(equalToConstant: 335),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -84),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 160)
        ])
    }
}
