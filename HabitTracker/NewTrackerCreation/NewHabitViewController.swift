//
//  NewHabitViewController.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit

protocol TrackerCreationDelegate: AnyObject {
    func didCreateTracker(_ tracker: Tracker, category: String)
}

protocol NewHabitViewControllerDelegate: AnyObject {
    func updateSubitle(nameSubitle: String)
    func updateDate(days: [String])
}

// MARK: - CreatingHabitViewController

final class NewHabitViewController: UIViewController {
    weak var delegate: TrackerCreationDelegate?
    weak var delegateEdit: EditTrackerDelegate?
    var numberOfDaysCompletedHabit: Int?
    var editCategoryHabit: String?
    var editTrackerHabit: Tracker?
    private let analyticsService = AnalyticsService()
    private let dataStorege = DataStorege.shared
    private let characterLimitInField = 38
    private var isSelectedColor: IndexPath?
    private var isSelectedEmoji: IndexPath?
    private let colors: [UIColor] = UIColor.colorSelection
    private var dateEvents = [Int]()
    private var creatingTrackersModel: [CreatingTrackersModel] = [
        CreatingTrackersModel(titleLabelText: NSLocalizedString("category", comment: "category"), subTitleLabel: ""),
        CreatingTrackersModel(titleLabelText: NSLocalizedString("schedule", comment: "schedule"), subTitleLabel: "")
    ]
    
    private let emojiList = [
        "🙂", "😻", "🌺", "🐶", "❤️", "😱",
        "😇", "😡", "🥶", "🤔", "🙌", "🍔",
        "🥦", "🏓", "🥇", "🎸", "🏝", "😪"
    ]
    
    // MARK: - UiElements
    
    private let contentView = UIView()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .ypWhiteDay
        scrollView.isScrollEnabled = true
        scrollView.isUserInteractionEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var newHabitLabel: UILabel = {
        let trackerLabel = UILabel()
        trackerLabel.text = NSLocalizedString("newHabit", comment: "newHabit")
        trackerLabel.textColor = .ypBlackDay
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
        button.setTitle(NSLocalizedString("create", comment: "create"), for: .normal)
        button.setTitleColor(.ypWhiteDay, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .ypGray
        button.isEnabled = false
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
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.register(EmojiCollectionViewCell.self, forCellWithReuseIdentifier: "EmojiCollectionViewCell")
        collectionView.register(ColorsCollectionViewCell.self, forCellWithReuseIdentifier: "ColorsCollectionViewCell")
        collectionView.register(SupplementaryView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
        collectionView.backgroundColor = .ypWhiteDay
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
        configViews()
        configConstraints()
        clearDataStorege()
        trackerEditing()
        analyticsService.report(event: .open, params: ["Screen" : "NewHabit"])
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        analyticsService.report(event: .close, params: ["Screen" : "NewHabit"])
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
        analyticsService.report(event: .click, params: ["Screen" : "NewHabit", "Item" : Items.cancelCreation.rawValue])
    }
    
    @objc
    private func create() {
        guard let newTracker = collectingDataForTheTracker(newTracker: true) else { return }
        let categoryTracker = creatingTrackersModel[0].subTitleLabel
        delegate?.didCreateTracker(newTracker, category: categoryTracker)
        analyticsService.report(event: .click, params: ["Screen" : "NewHabit", "Item" : Items.addTracker.rawValue])
        self.view.window?.rootViewController?.dismiss(animated: true) {
        }
    }
    
    @objc
    private func update() {
        guard let newTracker = collectingDataForTheTracker(newTracker: false) else { return }
        let categoryTracker = creatingTrackersModel[0].subTitleLabel
        delegateEdit?.trackerUpdate(newTracker, category: categoryTracker)
        analyticsService.report(event: .click, params: ["Screen" : "NewHabit", "Item" : Items.updateTracker.rawValue])
        dismiss(animated: true)
    }
    
    
    // MARK: - Private methods
    private func collectingDataForTheTracker(newTracker: Bool) -> Tracker? {
        guard let text = nameTrackerTextField.text,
              let selectedEmojiIndexPath = isSelectedEmoji,
              let selectedColorIndexPath = isSelectedColor else { return nil }
        let emoji = emojiList[selectedEmojiIndexPath.row]
        let color = colors[selectedColorIndexPath.row]
        if newTracker {
            return Tracker(id: UUID(), name: text, color: color, emoji: emoji, dateEvents: dateEvents, isPinned: false)
        } else {
            guard let id = editTrackerHabit?.id else { return nil }
            guard let isPinned = editTrackerHabit?.isPinned else { return nil }
            return Tracker(id: id, name: text, color: color, emoji: emoji, dateEvents: dateEvents, isPinned: isPinned)
        }
    }
    
    private func trackerEditing() {
        guard let daysLabel = numberOfDaysCompletedHabit else { return }
        guard let trackerForEditing = editTrackerHabit else { return }
        guard let categiryForEditing = editCategoryHabit else { return }
        newHabitLabel.text = NSLocalizedString("editing", comment: "editing")
        completedDaysLabel.isHidden = false
        creatingButton.setTitle(NSLocalizedString("save", comment: "save"), for: .normal)
        creatingButton.addTarget(self, action: #selector(self.update), for: .touchUpInside)
        completedDaysLabel.text = formatDaysText(forDays: daysLabel)
        nameTrackerTextField.text = trackerForEditing.name
        updateSubitle(nameSubitle: categiryForEditing)
        convertToDateFormatterInDay(trackerForEditing.dateEvents ?? [])
        if let emojiIndex = emojiList.firstIndex(of: trackerForEditing.emoji) {
            let emojieIndexPath = IndexPath(row: emojiIndex, section: 0)
            collectionView.selectItem(at: emojieIndexPath, animated: false, scrollPosition: [])
            collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: emojieIndexPath)
        }
        if let colorIndex = colors.firstIndex(where: { UIColor.colorComparison(colorFromSet: $0, trackerColor: trackerForEditing.color) }) {
            let colorIndexPath = IndexPath(row: colorIndex, section: 1)
            collectionView.selectItem(at: colorIndexPath, animated: false, scrollPosition: [])
            collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: colorIndexPath)
        }
        updateCreatingButton()
    }
    
    private func formatDaysText(forDays days: Int) -> String {
        if days > 10 && days < 20 {
            return "\(days) дней"
        } else {
            switch days % 10 {
            case 1:
                return "\(days) день"
            case 2, 3, 4:
                return "\(days) дня"
            default:
                return "\(days) дней"
            }
        }
    }
    
    private func convertToDateFormatterInDay(_ indices: [Int]) {
        let orderedDays = ["\(NSLocalizedString("Mon", comment: "Mon"))", "\(NSLocalizedString("Tue", comment: "Tue"))", "\(NSLocalizedString("Wed", comment: "Wed"))", "\(NSLocalizedString("Thu", comment: "Thu"))", "\(NSLocalizedString("Fri", comment: "Fri"))", "\(NSLocalizedString("Sat", comment: "Sat"))", "\(NSLocalizedString("Sun", comment: "Sun"))"]
        let resultArray = indices.compactMap { (index: Int) -> String? in
            guard (1...orderedDays.count).contains(index) else { return nil }
            return orderedDays[index - 1]
        }
        updateDate(days: resultArray)
    }
    
    
    private func updateCreatingButton() {
        let categoryForActiveButton = creatingTrackersModel[0].subTitleLabel
        let weekDayForActiveButton = creatingTrackersModel[1].subTitleLabel
        guard let selectedEmojiIndexPathHabbit = isSelectedEmoji else { return }
        guard let selectedColorIndexPathHabbit = isSelectedColor else { return }
        creatingButton.isEnabled = nameTrackerTextField.text?.isEmpty == false && categoryForActiveButton.isEmpty == false && weekDayForActiveButton.isEmpty == false && selectedEmojiIndexPathHabbit.isEmpty == false && selectedColorIndexPathHabbit.isEmpty == false
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
    
    private func configViews() {
        _ = self.skipKeyboard
        scrollView.delegate = self
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .ypWhiteDay
        view.addSubview(newHabitLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackViewForTextField)
        contentView.addSubview(tableView)
        contentView.addSubview(collectionView)
        contentView.addSubview(cancelButton)
        contentView.addSubview(creatingButton)
        contentView.addSubview(completedDaysLabel)
    }
    
    private func configConstraints() {
        let nameTrackerTextFieldConstant: CGFloat = editTrackerHabit == nil ? 28 : 106
        let scrollHeightAnchor: CGFloat = editTrackerHabit == nil ? 32 : 102
        NSLayoutConstraint.activate([
            newHabitLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            newHabitLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 27),
            
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            contentView.heightAnchor.constraint(equalToConstant: view.frame.height + scrollHeightAnchor),
            
            completedDaysLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            completedDaysLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            completedDaysLabel.heightAnchor.constraint(equalToConstant: 38),
            
            nameTrackerTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: nameTrackerTextFieldConstant),
            nameTrackerTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameTrackerTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameTrackerTextField.heightAnchor.constraint(equalToConstant: 75),
            
            errorLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            tableView.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            tableView.heightAnchor.constraint(equalToConstant: 149),
            
            collectionView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 32),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 490),
            
            cancelButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 16),
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            cancelButton.widthAnchor.constraint(equalToConstant: 168),
            
            creatingButton.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor, constant: 8),
            creatingButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 16),
            creatingButton.heightAnchor.constraint(equalToConstant: 60),
            creatingButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
}

extension NewHabitViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
}

// MARK: - CreatingHabitViewControllerDelegate

extension NewHabitViewController: NewHabitViewControllerDelegate {
    func updateDate(days: [String]) {
        if !days.isEmpty {
            if days.count == 7 {
                creatingTrackersModel[1].subTitleLabel = NSLocalizedString("everyDay", comment: "everyDay")
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
        let orderedDays = ["\(NSLocalizedString("Mon", comment: "Mon"))", "\(NSLocalizedString("Tue", comment: "Tue"))", "\(NSLocalizedString("Wed", comment: "Wed"))", "\(NSLocalizedString("Thu", comment: "Thu"))", "\(NSLocalizedString("Fri", comment: "Fri"))", "\(NSLocalizedString("Sat", comment: "Sat"))", "\(NSLocalizedString("Sun", comment: "Sun"))"]
        let resultArray = days.compactMap { orderedDays.firstIndex(of: $0)?.advanced(by: 1) }
        dateEvents = resultArray
    }
}

// MARK: - UITextFieldDelegate

extension NewHabitViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let textField = textField.text ?? ""
        let newLength = textField.count + string.count - range.length
        return newLength <= characterLimitInField
    }
}

// MARK: - CreatingHabitViewController

extension NewHabitViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let categoryViewController = TrackerCategoryViewController()
            let categoryViewModel = TrackerCategoryViewModel()
            categoryViewController.initialize(viewModel: categoryViewModel)
            categoryViewModel.delegateHabbit = self
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

extension NewHabitViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewTableCell", for: indexPath) as? NewTableCell
        else { fatalError() }
        let data = creatingTrackersModel[indexPath.row]
        cell.configureCell(title: data.titleLabelText, subTitle: data.subTitleLabel)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension NewHabitViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if let selectedCell = isSelectedEmoji {
                let cell = collectionView.cellForItem(at: selectedCell)
                cell?.backgroundColor = .clear
                collectionView.deselectItem(at: selectedCell, animated: true)
            }
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.cornerRadius = 16
            cell?.backgroundColor = .ypBackgroundDay
            isSelectedEmoji = indexPath
            updateCreatingButton()
        } else if indexPath.section == 1 {
            if let selectedCell = isSelectedColor {
                let cell = collectionView.cellForItem(at: selectedCell)
                cell?.layer.borderWidth = 0
                collectionView.deselectItem(at: selectedCell, animated: true)
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

extension NewHabitViewController: UICollectionViewDataSource {
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
            cell.backgroundColor = cell.isSelected ? UIColor.ypLightGray : .clear
            return cell
        case 1:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ColorsCollectionViewCell",
                for: indexPath
            ) as? ColorsCollectionViewCell else { return UICollectionViewCell()}
            cell.sizeToFit()
            cell.colorView.backgroundColor = colors[indexPath.row]
            return cell
        default: return UICollectionViewCell()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension NewHabitViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as? SupplementaryView else { return UICollectionReusableView()}
        indexPath.section == 0 ? (view.titleLabel.text = "Emoji") : (view.titleLabel.text = NSLocalizedString("color", comment: "color"))
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 52, height: 52)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 24, left: 18, bottom: 24, right: 18)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let indexPath = IndexPath(row: 0, section: section)
        let headerView = self.collectionView(
            collectionView,
            viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader,
            at: indexPath
        )
        return headerView.systemLayoutSizeFitting(CGSize(
            width: collectionView.frame.width,
            height: UIView.layoutFittingExpandedSize.height),
                                                  withHorizontalFittingPriority: .required,
                                                  verticalFittingPriority: .fittingSizeLevel)
    }
}
