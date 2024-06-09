//
//  CreatingCategoryViewController.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit

final class CreatingCategoryViewController: UIViewController {
    weak var delegate: TrackerCategoryViewModelDelegate?
    private let characterLimitInField = 38
    
    // MARK: - UiElements
    
    private lazy var habitLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("newCategory", comment: "newCategory")
        label.textColor = .ypBlackDay
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var nameTrackerTextField: UITextField = {
        let textField = UITextField()
        textField.indent(size: 16)
        textField.placeholder = NSLocalizedString("nameOfCategory", comment: "nameOfCategory")
        textField.textColor = .ypBlackDay
        textField.backgroundColor = .ypBackgroundDay
        textField.layer.cornerRadius = 16
        textField.font = .systemFont(ofSize: 17)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        UITextField.appearance().clearButtonMode = .whileEditing
        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        return textField
    }()
    
    private lazy var creatingCategoryButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("ready", comment: "ready"), for: .normal)
        button.setTitleColor(.ypWhiteDay, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .ypGray
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(self.actionsForButton), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configViews()
        configConstraints()
    }
    
    // MARK: - Actions
    
    @objc func actionsForButton() {
        guard let nameCategory = nameTrackerTextField.text else { return }
        delegate?.updateData(nameCategory: nameCategory)
        dismiss(animated: true)
    }
    
    @objc func textFieldChanged() {
        guard let numberOfCharacters = nameTrackerTextField.text?.count else { return }
        if numberOfCharacters < characterLimitInField || numberOfCharacters > 0{
            updateCreatingButton()
        }
    }
    
    //MARK: - Private methods
    
    private func updateCreatingButton() {
        creatingCategoryButton.isEnabled = nameTrackerTextField.text?.isEmpty == false
        if creatingCategoryButton.isEnabled {
            creatingCategoryButton.backgroundColor = .ypBlackDay
        } else {
            creatingCategoryButton.backgroundColor = .ypGray
        }
    }
    
    private func configViews() {
        _ = self.skipKeyboard
        view.backgroundColor = .ypWhiteDay
        view.addSubview(habitLabel)
        view.addSubview(nameTrackerTextField)
        view.addSubview(creatingCategoryButton)
    }
    
    private func configConstraints() {
        NSLayoutConstraint.activate([
            habitLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            habitLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 27),
            
            nameTrackerTextField.topAnchor.constraint(equalTo: habitLabel.bottomAnchor, constant: 38),
            nameTrackerTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameTrackerTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameTrackerTextField.heightAnchor.constraint(equalToConstant: 75),
            
            creatingCategoryButton.heightAnchor.constraint(equalToConstant: 60),
            creatingCategoryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            creatingCategoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            creatingCategoryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
}

extension CreatingCategoryViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let textField = textField.text ?? ""
        let newLength = textField.count + string.count - range.length
        return newLength <= characterLimitInField
    }
}

extension UIViewController {
    var skipKeyboard: UITapGestureRecognizer {
        let skipKeyboard = UITapGestureRecognizer (
            target: self,
            action: #selector(hideKeyboard))
        skipKeyboard.cancelsTouchesInView = false
        view.addGestureRecognizer(skipKeyboard)
        return skipKeyboard
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
}
