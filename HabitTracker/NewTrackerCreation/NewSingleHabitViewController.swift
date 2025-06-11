//
//  NewSingleHabitViewController.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit

protocol NewSingleHabitViewControllerDelegate: AnyObject {
    func updateSubitle(nameSubitle: String)
}

// MARK: - CreatingHabitViewController

final class NewSingleHabitViewController: UIViewController {
    weak var delegate: TrackerCreationDelegate?
    weak var delegateEdit: EditTrackerDelegate?
    var deadlineDaysLeft: Int?
    var editCategoryIrregular: String?
    var editTrackerIrregular: Tracker?
    private let analyticsService = AnalyticsService()
    private let dataStorege = DataStorege.shared
    private let characterLimitInField = 38
    private var isSelectedEmoji: IndexPath?
    private var isSelectedColor: IndexPath?
    private let colors: [UIColor] = UIColor.colorSelection
    private var creatingTrackersModel: [CreatingTrackersModel] = [
        CreatingTrackersModel(titleLabelText: NSLocalizedString("category", comment: "category"), subTitleLabel: "")
    ]
    
    private let emojiList = [
        "🙂", "😻", "🌺", "🐶", "❤️", "😱",
        "😇", "😡", "🥶", "🤔", "🙌", "🍔",
        "🥦", "🏓", "🥇", "🎸", "🏝", "😪"
    ]
    
    //MARK: - UiElements
    
    private let contentView = UIView()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .ypWhite
        scrollView.isScrollEnabled = true
        scrollView.isUserInteractionEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var newHabitLabel: UILabel = {
        let trackerLabel = UILabel()
        trackerLabel.text = NSLocalizedString("newIrrEvent", comment: "newIrrEvent")
        trackerLabel.textColor = .ypBlack
        trackerLabel.font = .systemFont(ofSize: 16, weight: .medium)
        trackerLabel.translatesAutoresizingMaskIntoConstraints = false
        return trackerLabel
    }()
    
    private lazy var completedDaysLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.isHidden = true
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var nameTrackerTextField: UITextField = {
        let textField = UITextField()
        textField.indent(size: 16)
        textField.placeholder = NSLocalizedString("nameOfTracker", comment: "nameOfTracker")
        textField.textColor = .ypBlack
        textField.backgroundColor = .ypWhite
        textField.layer.cornerRadius = 16
        textField.font = .systemFont(ofSize: 17)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        UITextField.appearance().clearButtonMode = .whileEditing
        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        textField.layer.borderWidth = 2
        textField.layer.borderColor = UIColor.ypBlue.cgColor
        return textField
    }()
    
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("limit", comment: "limit")
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
        button.accessibilityIdentifier = "cancelButton"
        button.setTitle(NSLocalizedString("cancel", comment: "cancel"), for: .normal)
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
        button.accessibilityIdentifier = "creatingButton"
        button.setTitle(NSLocalizedString("create", comment: "create"), for: .normal)
        button.setTitleColor(.ypWhite, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .ypGray
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(NewTableCell.self, forCellReuseIdentifier: "NewTableCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.layer.cornerRadius = 16
        tableView.layer.masksToBounds = true
        tableView.isScrollEnabled = false
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private lazy var deadlinePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        picker.translatesAutoresizingMaskIntoConstraints = false
        if editTrackerIrregular == nil {
            picker.minimumDate = Date()
        }
        return picker
    }()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.register(EmojiCollectionViewCell.self, forCellWithReuseIdentifier: "EmojiCollectionViewCell")
        collectionView.register(ColorsCollectionViewCell.self, forCellWithReuseIdentifier: "ColorsCollectionViewCell")
        collectionView.register(SupplementaryView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
        collectionView.backgroundColor = .ypWhite
        collectionView.allowsMultipleSelection = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isScrollEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataStorege.removeIndexPathForCheckmark()
        configViews()
        configConstraints()
        deadlinePicker.addTarget(self, action: #selector(deadlineChanged), for: .valueChanged)
        if let _ = editTrackerIrregular, let _ = editCategoryIrregular, let daysLeft = deadlineDaysLeft {
            selectedDate = editTrackerIrregular?.deadline ?? Date()
            trackerEditing(daysLeft: daysLeft)
        } else {
            selectedDate = Date()
            updatePlannedEventLabel()
        }
        analyticsService.report(event: .open, params: ["Screen" : "NewSingleHabit"])
        updateDeadlineLabel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startDeadlineTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopDeadlineTimer()
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
        analyticsService.report(event: .click, params: ["Screen" : "NewSingleHabit", "Item" : Items.cancelCreation.rawValue])
        dismiss(animated: true)
    }
    
    @objc
    private func create() {
        guard let newTracker = collectingDataForTheTracker(newTracker: true) else { return }
        let categoryTracker = creatingTrackersModel[0].subTitleLabel
        delegate?.didCreateTracker(newTracker, category: categoryTracker)
        analyticsService.report(event: .click, params: ["Screen" : "NewSingleHabit", "Item" : Items.addTracker.rawValue])
        dismiss(animated: true)
    }
    
    @objc
    private func update() {
        guard let newTracker = collectingDataForTheTracker(newTracker: false) else { return }
        let categoryTracker = creatingTrackersModel[0].subTitleLabel
        delegateEdit?.trackerUpdate(newTracker, category: categoryTracker)
        analyticsService.report(event: .click, params: ["Screen" : "NewSingleHabit", "Item" : Items.updateTracker.rawValue])
        dismiss(animated: true)
    }
    
    @objc
    private func deadlineChanged() {
        selectedDate = deadlinePicker.date
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let deadlineDay = calendar.startOfDay(for: deadlinePicker.date)
        let daysLeft = calendar.dateComponents([.day], from: today, to: deadlineDay).day ?? 0
        if editTrackerIrregular != nil {
            let deadlineText = irregularEditDeadline(daysLeft: daysLeft)
            if deadlineText.hasPrefix("[done]") {
                completedDaysLabel.text = String(deadlineText.dropFirst(6))
                completedDaysLabel.textColor = .white
            } else {
                completedDaysLabel.text = deadlineText
                completedDaysLabel.textColor = .white
            }
        } else {
            completedDaysLabel.text = formatScheduledTime(daysLeft)
        }
    }
    
    private func updatePlannedEventLabel() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let eventDay = calendar.startOfDay(for: selectedDate)
        let daysLeft = calendar.dateComponents([.day], from: today, to: eventDay).day ?? 0
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: selectedDate)
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
        let dateString = dateFormatter.string(from: selectedDate)
        if daysLeft == 0 {
            completedDaysLabel.text = "Сегодня, \(timeString)"
        } else if daysLeft == 1 {
            completedDaysLabel.text = "Завтра, \(timeString)"
        } else {
            completedDaysLabel.text = "\(dateString), \(timeString)"
        }
    }

    private func declensionDays(_ days: Int) -> String {
        let lastDigit = days % 10
        let lastTwoDigits = days % 100
        if lastTwoDigits >= 11 && lastTwoDigits <= 14 {
            return "дней"
        }
        switch lastDigit {
        case 1: return "день"
        case 2, 3, 4: return "дня"
        default: return "дней"
        }
    }
    
    private func formatScheduledTime(_ days: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: deadlinePicker.date)
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
        let dateString = dateFormatter.string(from: deadlinePicker.date)
        if days == 0 {
            return "Сегодня, \(timeString)"
        } else if days == 1 {
            return "Завтра, \(timeString)"
        } else {
            return "\(dateString), \(timeString)"
        }
    }
    
    // MARK: - Private methods
    
    private func collectingDataForTheTracker(newTracker: Bool) -> Tracker? {
        guard let text = nameTrackerTextField.text,
              let selectedEmojiIndexPath = isSelectedEmoji,
              let selectedColorIndexPath = isSelectedColor else { return nil }
        let emoji = emojiList[selectedEmojiIndexPath.row]
        let color = colors[selectedColorIndexPath.row]
        let deadline = selectedDate
        if newTracker {
            return Tracker(id: UUID(), name: text, color: color, emoji: emoji, isPinned: false, createdAt: Date(), deadline: deadline, isIrregular: true, status: "")
        } else {
            guard let id = editTrackerIrregular?.id else { return nil }
            guard let isPinned = editTrackerIrregular?.isPinned else { return nil }
            return Tracker(id: id, name: text, color: color, emoji: emoji, isPinned: isPinned, createdAt: editTrackerIrregular?.createdAt, deadline: deadline, isIrregular: true, status: "")
        }
    }
    
    private func trackerEditing(daysLeft: Int) {
        guard let trackerForEditing = editTrackerIrregular else { return }
        guard let categiryForEditing = editCategoryIrregular else { return }
        newHabitLabel.text = NSLocalizedString("editing", comment: "editing")
        completedDaysLabel.isHidden = false
        creatingButton.setTitle(NSLocalizedString("save", comment: "save"), for: .normal)
        creatingButton.addTarget(self, action: #selector(self.update), for: .touchUpInside)
        let deadlineText = irregularEditDeadline(daysLeft: daysLeft)
        if deadlineText.hasPrefix("[done]") {
            completedDaysLabel.text = String(deadlineText.dropFirst(6))
            completedDaysLabel.textColor = .white
        } else {
            completedDaysLabel.text = deadlineText
            completedDaysLabel.textColor = .white
        }
        nameTrackerTextField.text = trackerForEditing.name
        updateSubitle(nameSubitle: categiryForEditing)
        if let emojiIndex = emojiList.firstIndex(of: trackerForEditing.emoji) {
            let emojieIndexPath = IndexPath(row: emojiIndex, section: 0)
            collectionView.selectItem(at: emojieIndexPath, animated: false, scrollPosition: [])
            collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: emojieIndexPath)
        }
        if let colorIndex = colors.firstIndex(where: { $0 == trackerForEditing.color }) {
            let colorIndexPath = IndexPath(row: colorIndex, section: 1)
            collectionView.selectItem(at: colorIndexPath, animated: false, scrollPosition: [])
            collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: colorIndexPath)
        }
        if let deadline = trackerForEditing.deadline {
            selectedDate = deadline
            deadlinePicker.date = deadline
        } else {
            selectedDate = Date()
            deadlinePicker.date = Date()
        }
        updateCreatingButton()
    }
    
    private func irregularEditDeadline(daysLeft: Int) -> String {
        let deadline = deadlinePicker.date
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: deadline)
        if daysLeft == 0 {
            if deadline < Date() {
                return "Событие завершено"
            } else {
                return "Сегодня в \(timeString)"
            }
        } else if daysLeft == 1 {
            return "До события: 1 день"
        } else if daysLeft > 1 {
            return "До события: \(daysLeft) " + declensionDays(daysLeft)
        } else if daysLeft < 0 {
            return "Событие завершено"
        } else {
            return ""
        }
    }

    private func declensionHours(_ hours: Int) -> String {
        let lastDigit = hours % 10
        let lastTwoDigits = hours % 100
        if lastTwoDigits >= 11 && lastTwoDigits <= 14 {
            return "часов"
        }
        switch lastDigit {
        case 1: return "час"
        case 2, 3, 4: return "часа"
        default: return "часов"
        }
    }
    
    //MARK: - Private methods
    
    private func updateCreatingButton() {
        let categoryForActivButton = creatingTrackersModel[0].subTitleLabel
        guard let selectedEmojiIndexPath = isSelectedEmoji else { return }
        guard let selectedColorIndexPath = isSelectedColor else { return }
        creatingButton.isEnabled = nameTrackerTextField.text?.isEmpty == false && categoryForActivButton.isEmpty == false && selectedEmojiIndexPath.isEmpty == false && selectedColorIndexPath.isEmpty == false
        if creatingButton.isEnabled {
            creatingButton.backgroundColor = .ypBlack
        } else {
            creatingButton.isEnabled = false
            creatingButton.backgroundColor = .ypGray
        }
    }
    
    private func configViews() {
        _ = self.skipKeyboard
        scrollView.delegate = self
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .ypWhite
        view.addSubview(newHabitLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackViewForTextField)
        contentView.addSubview(tableView)
        contentView.addSubview(deadlinePicker)
        contentView.addSubview(collectionView)
        contentView.addSubview(cancelButton)
        contentView.addSubview(creatingButton)
        contentView.addSubview(completedDaysLabel)
    }
    
    private func configConstraints() {
        let nameTrackerTextFieldConstant: CGFloat = editTrackerIrregular == nil ? 28 : 106
        let collectionViewHeight: CGFloat = 420
        NSLayoutConstraint.activate([
            newHabitLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            newHabitLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scrollView.topAnchor.constraint(equalTo: newHabitLabel.bottomAnchor, constant: 8),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            completedDaysLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            completedDaysLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackViewForTextField.topAnchor.constraint(equalTo: completedDaysLabel.bottomAnchor, constant: nameTrackerTextFieldConstant),
            stackViewForTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackViewForTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackViewForTextField.heightAnchor.constraint(equalToConstant: 75),
            errorLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            tableView.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            tableView.heightAnchor.constraint(equalToConstant: 75),
            deadlinePicker.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 16),
            deadlinePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            deadlinePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            collectionView.topAnchor.constraint(equalTo: deadlinePicker.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: collectionViewHeight),
            cancelButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 16),
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            cancelButton.widthAnchor.constraint(equalToConstant: 168),
            creatingButton.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor, constant: 8),
            creatingButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 16),
            creatingButton.heightAnchor.constraint(equalToConstant: 60),
            creatingButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            creatingButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private var selectedDate: Date = Date()
    private var deadlineTimer: Timer?

    private func startDeadlineTimer() {
        deadlineTimer?.invalidate()
        deadlineTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateDeadlineLabel()
        }
    }

    private func stopDeadlineTimer() {
        deadlineTimer?.invalidate()
        deadlineTimer = nil
    }

    private func updateDeadlineLabel() {
        if let tracker = editTrackerIrregular, let _ = editCategoryIrregular, let daysLeft = deadlineDaysLeft {
            let deadlineText = irregularEditDeadline(daysLeft: daysLeft)
            completedDaysLabel.text = deadlineText
            completedDaysLabel.textColor = .label
        }
    }
}

extension NewSingleHabitViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
}
// MARK: - CreatingIrregularEventViewControllerDelegate

extension NewSingleHabitViewController: NewSingleHabitViewControllerDelegate {
    func updateSubitle(nameSubitle: String) {
        creatingTrackersModel[0].subTitleLabel = nameSubitle
        tableView.reloadData()
        updateCreatingButton()
    }
}

// MARK: - UITextFieldDelegate

extension NewSingleHabitViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let textField = textField.text ?? ""
        let newLength = textField.count + string.count - range.length
        return newLength <= characterLimitInField
    }
}

// MARK: - UITableViewDelegate

extension NewSingleHabitViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let categoryViewController = TrackerCategoryViewController()
            let categoryViewModel = TrackerCategoryViewModel()
            categoryViewController.initialize(viewModel: categoryViewModel)
            categoryViewModel.delegateIrregular = self
            let navigationController = UINavigationController(rootViewController: categoryViewController)
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

extension NewSingleHabitViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewTableCell", for: indexPath) as? NewTableCell else { fatalError() }
        let data = creatingTrackersModel[0]
        cell.configureCell(title: data.titleLabelText, subTitle: data.subTitleLabel)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension NewSingleHabitViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if let selectedCell = isSelectedEmoji {
                let cell = collectionView.cellForItem(at: selectedCell) as? EmojiCollectionViewCell
                cell?.layer.borderWidth = 0
                cell?.layer.borderColor = UIColor.clear.cgColor
            }
            let cell = collectionView.cellForItem(at: indexPath) as? EmojiCollectionViewCell
            cell?.layer.cornerRadius = 16
            cell?.layer.borderWidth = 3
            cell?.layer.borderColor = UIColor.ypBlue.cgColor
            isSelectedEmoji = indexPath
            updateCreatingButton()
        } else if indexPath.section == 1 {
            if let selectedCell = isSelectedColor {
                let cell = collectionView.cellForItem(at: selectedCell)
                cell?.layer.borderWidth = 0
            }
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.cornerRadius = 8
            cell?.layer.borderWidth = 3
            cell?.layer.borderColor = UIColor.colorSelection[indexPath.row].withAlphaComponent(0.3).cgColor
            isSelectedColor = indexPath
            updateCreatingButton()
        }
    }
}

// MARK: - UICollectionViewDataSource

extension NewSingleHabitViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? emojiList.count : colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "EmojiCollectionViewCell",
                for: indexPath
            ) as? EmojiCollectionViewCell else { return UICollectionViewCell()}
            cell.titleLabel.text = emojiList[indexPath.row]
            cell.backgroundColor = .clear
            return cell
        case 1:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ColorsCollectionViewCell",
                for: indexPath
            ) as? ColorsCollectionViewCell else { return UICollectionViewCell()}
            cell.sizeToFit()
            cell.configure(with: colors[indexPath.row])
            return cell
        default: return UICollectionViewCell()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension NewSingleHabitViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 52, height: 52)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 24, left: 18, bottom: 24, right: 18)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 || section == 1 {
            return CGSize(width: collectionView.frame.width, height: 40)
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as? SupplementaryView else { return UICollectionReusableView()}
        view.titleLabel.text = indexPath.section == 0 ? NSLocalizedString("emoji", comment: "emoji") : NSLocalizedString("color", comment: "color")
        return view
    }
}

