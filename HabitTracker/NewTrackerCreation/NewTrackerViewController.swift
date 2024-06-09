//
//  NewTrackerViewController.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit

// MARK: - CreatingNewTrackerViewController

final class NewTrackerViewController: UIViewController {
    weak var delegate: TrackerCreationDelegate?
    private let analyticsService = AnalyticsService()
    
    //MARK: - UiElements
    
    private lazy var creatingTrackerLabel: UILabel = {
        let trackerLabel = UILabel()
        trackerLabel.text = NSLocalizedString("trackerCreation", comment: "trackerCreation")
        trackerLabel.textColor = .ypBlackDay
        trackerLabel.font = .systemFont(ofSize: 16, weight: .medium)
        trackerLabel.translatesAutoresizingMaskIntoConstraints = false
        return trackerLabel
    }()
    
    private lazy var creatingHabitButton: UIButton = {
        let title = NSLocalizedString("habit", comment: "habit")
        let button = addActionsForButton(title: title, action: #selector(creatingHabit))
        button.accessibilityIdentifier = "creatingHabitButton"
        return button
    }()
    
    private lazy var creatingIrregularEventButton: UIButton = {
        let title = NSLocalizedString("irrEvent", comment: "irrEvent")
        let button = addActionsForButton(title: title, action: #selector(creatingIrregularEvent))
        button.accessibilityIdentifier = "createIrregularEventButton"
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configViews()
        configConstraints()
        analyticsService.report(event: .open, params: ["Screen" : "NewTracker"])
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        analyticsService.report(event: .close, params: ["Screen" : "NewTracker"])
    }
    
    // MARK: - Actions
    
    @objc
    private func creatingHabit() {
        let createHabitViewController = NewHabitViewController()
        createHabitViewController.delegate = self.delegate
        let navigationController = UINavigationController(rootViewController: createHabitViewController)
        present(navigationController, animated: true)
        analyticsService.report(event: .click, params: ["Screen" : "NewHabitViewController"])
    }
    
    @objc
    private func creatingIrregularEvent() {
        let createIrregularEventViewController = NewSingleHabitViewController()
        createIrregularEventViewController.delegate = self.delegate
        let navigationController = UINavigationController(rootViewController: createIrregularEventViewController)
        analyticsService.report(event: .click, params: ["Screen" : "NewSingleHabitViewController"])
        present(navigationController, animated: true)
    }
    
    //MARK: - Private methods
    
    private func configViews() {
        view.backgroundColor = .ypWhiteDay
        view.addSubview(creatingTrackerLabel)
        view.addSubview(creatingHabitButton)
        view.addSubview(creatingIrregularEventButton)
    }
    
    private func configConstraints() {
        NSLayoutConstraint.activate([
            creatingTrackerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            creatingTrackerLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 27),
            
            creatingHabitButton.heightAnchor.constraint(equalToConstant: 60),
            creatingHabitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            creatingHabitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            creatingHabitButton.topAnchor.constraint(equalTo: creatingTrackerLabel.bottomAnchor, constant: 281),
            
            creatingIrregularEventButton.topAnchor.constraint(equalTo: creatingHabitButton.bottomAnchor, constant: 16),
            creatingIrregularEventButton.heightAnchor.constraint(equalToConstant: 60),
            creatingIrregularEventButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            creatingIrregularEventButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func addActionsForButton(title: String, action: Selector) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.setTitleColor(.ypWhiteDay, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .ypBlackDay
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
}

