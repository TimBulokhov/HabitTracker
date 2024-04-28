//
//  NewHabitViewController.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit

protocol TrackerCreationDelegate: AnyObject {
    func didCreateTracker(_ tracker: Tracker, category: TrackerCategory)
}

protocol CreatingHabitViewControllerDelegate: AnyObject {
    func updateSubitle(nameSubitle: String)
    func updateDate(days: [String])
}

// MARK: - CreatingHabitViewController

final class CreatingHabitViewController: UIViewController {
    weak var delegate: TrackerCreationDelegate?
    private let dataStorege = DataStorege.shared
    private let characterLimitInField = 38
    private let color: UIColor = .colorSelection.randomElement()!
    private var dateEvents = [Int]()
    private var creatingTrackersModel: [CreatingTrackersModel] = [
        CreatingTrackersModel(titleLabelText: "Категория", subTitleLabel: ""),
        CreatingTrackersModel(titleLabelText: "Расписание", subTitleLabel: "")
    ]
    
    // MARK: - UiElements
    
    private var tableView: UITableView = .init()
    
    private lazy var newHabitLabel: UILabel = {
        let trackerLabel = UILabel()
        trackerLabel.text = "Новая привычка"
        trackerLabel.textColor = .ypBlackDay
        trackerLabel.font = .systemFont(ofSize: 16, weight: .medium)
        trackerLabel.translatesAutoresizingMaskIntoConstraints = false
        return trackerLabel
    }()
    
    private lazy var nameTrackerTextField: UITextField = {
        let textField = UITextField()
        textField.indent(size: 16)
        textField.placeholder = "Введите название трекера"
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
    
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.text = "Ограничение 38 символов"
        label.textColor = .ypRed
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var stackViewForTextField: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameTrackerTextField, errorLabel])
        stackView.distribution = .fill
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(self.cancelCreation), for: .touchUpInside)
        button.setTitle("Отменить", for: .normal)
        button.setTitleColor(.ypRed, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .clear
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.ypRed.cgColor
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var creatingButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(self.create), for: .touchUpInside)
        button.setTitle("Создать", for: .normal)
        button.setTitleColor(.ypWhiteDay, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .ypGray
        button.isEnabled = false
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configViews()
        configTableView()
        configConstraints()
        clearDataStorege()
    }
    
    // MARK: - Actions
    
    @objc func textFieldChanged() {
        guard let numberOfCharacters = nameTrackerTextField.text?.count else { return }
        if numberOfCharacters < characterLimitInField{
            errorLabel.isHidden = true
            updateCreatingButton()
        } else {
            errorLabel.isHidden = false
        }
    }
    
    @objc
    private func cancelCreation() {
        dismiss(animated: true)
    }
    
    @objc
    private func create() {
        guard let text = nameTrackerTextField.text else { return }
        let newTracker = Tracker(id: UUID(), name: text, color: color, emoji: "𓀡", dateEvents: dateEvents)
        let categoryTracker = TrackerCategory(title: creatingTrackersModel[0].subTitleLabel, trackers: [newTracker])
        delegate?.didCreateTracker(newTracker, category: categoryTracker)
        self.view.window?.rootViewController?.dismiss(animated: true) {
        }
    }
    
    // MARK: - Private methods
    
    private func updateCreatingButton() {
        let categoryForActivButton = creatingTrackersModel[0].subTitleLabel
        let weekDayForActivButton = creatingTrackersModel[1].subTitleLabel
        creatingButton.isEnabled = nameTrackerTextField.text?.isEmpty == false && categoryForActivButton.isEmpty == false && weekDayForActivButton.isEmpty == false
        if creatingButton.isEnabled {
            creatingButton.backgroundColor = .ypBlackDay
        } else {
            creatingButton.isEnabled = false
            creatingButton.backgroundColor = .ypGray
        }
    }
    
    private func clearDataStorege() {
        dataStorege.removeAllDaysInAWeek()
        dataStorege.removeIndexPathForCheckmark()
    }
    
    private func configTableView() {
        tableView.register(CreatingTableCell.self, forCellReuseIdentifier: "CreatingTableCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = .ypGray
        tableView.layer.cornerRadius = 16
        tableView.layer.masksToBounds = true
        tableView.isScrollEnabled = false
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tableView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func configViews() {
        _ = self.skipKeyboard
        view.backgroundColor = .ypWhiteDay
        view.addSubview(newHabitLabel)
        view.addSubview(stackViewForTextField)
        view.addSubview(tableView)
        view.addSubview(cancelButton)
        view.addSubview(creatingButton)
    }
    
    private func configConstraints() {
        NSLayoutConstraint.activate([
            newHabitLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            newHabitLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 27),
            nameTrackerTextField.topAnchor.constraint(equalTo: newHabitLabel.bottomAnchor, constant: 28),
            nameTrackerTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameTrackerTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameTrackerTextField.heightAnchor.constraint(equalToConstant: 75),
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tableView.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.heightAnchor.constraint(equalToConstant: 149),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            cancelButton.widthAnchor.constraint(equalToConstant: 168),
            creatingButton.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor, constant: 8),
            creatingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            creatingButton.heightAnchor.constraint(equalToConstant: 60),
            creatingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
}

// MARK: - CreatingHabitViewControllerDelegate

extension CreatingHabitViewController: CreatingHabitViewControllerDelegate {
    func updateDate(days: [String]) {
        if !days.isEmpty {
            if days.count == 7 {
                creatingTrackersModel[1].subTitleLabel = "Каждый день"
                convertToDayInDateFormatter(days)
            } else {
                creatingTrackersModel[1].subTitleLabel = days.joined(separator: ", ")
                convertToDayInDateFormatter(days)
            }
        }
        tableView.reloadData()
        updateCreatingButton()
    }
    
    func updateSubitle(nameSubitle: String) {
        creatingTrackersModel[0].subTitleLabel = nameSubitle
        tableView.reloadData()
        updateCreatingButton()
    }
    
    private func convertToDayInDateFormatter(_ days: [String]){
        let orderedDays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
        let resultArray = days.compactMap { orderedDays.firstIndex(of: $0)?.advanced(by: 1) }
        dateEvents = resultArray
    }
}

// MARK: - UITextFieldDelegate

extension CreatingHabitViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let textField = textField.text ?? ""
        let newLength = textField.count + string.count - range.length
        return newLength <= characterLimitInField
    }
}

// MARK: - CreatingHabitViewController

extension CreatingHabitViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let categoryViewController = CategoryViewController()
            categoryViewController.delegateHabbit = self
            let navigationController = UINavigationController(rootViewController: categoryViewController)
            present(navigationController, animated: true)
        case 1:
            let scheduleViewController = ScheduleViewController()
            scheduleViewController.delegate = self
            let navigationController = UINavigationController(rootViewController: scheduleViewController)
            present(navigationController, animated: true)
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
}

// MARK: - UITableViewDataSource

extension CreatingHabitViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CreatingTableCell", for: indexPath) as? CreatingTableCell
        else { fatalError() }
        let data = creatingTrackersModel[indexPath.row]
        cell.configureCell(title: data.titleLabelText, subTitle: data.subTitleLabel)
        return cell
    }
}
