//
//  NewHabitViewController.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit
import MobileCoreServices
import AVKit
import UniformTypeIdentifiers
import FirebaseFirestore

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
    var deadlineDaysLeft: Int?
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
        CreatingTrackersModel(titleLabelText: NSLocalizedString("status", comment: "status"), subTitleLabel: "Создана")
    ]
    
    private let emojiList = [
        "🙂", "😻", "🌺", "🐶", "❤️", "😱",
        "😇", "😡", "🥶", "🤔", "🙌", "🍔",
        "🥦", "🏓", "🥇", "🎸", "🏝", "😪"
    ]
    
    private let statusOptions = [
        ("created", "Создана", UIColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1)),
        ("in_progress", "В процессе", UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1)),
        ("completed", "Выполнена", UIColor(red: 66/255, green: 170/255, blue: 255/255, alpha: 1)),
        ("testing", "Тестируется", UIColor(red: 247/255, green: 148/255, blue: 60/255, alpha: 1)),
        ("ready_for_release", "Готово к релизу", UIColor(red: 0/255, green: 165/255, blue: 80/255, alpha: 1)),
        ("done", "Завершена", UIColor(red: 102/255, green: 0/255, blue: 153/255, alpha: 1))
    ]
    
    private let assigneeCharacterLimit = 38
    
    // MARK: - UiElements
    
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
        trackerLabel.text = NSLocalizedString("newHabit", comment: "newHabit")
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
    
    private lazy var errorAssigneeLabel: UILabel = {
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
        button.setTitleColor(.ypWhite, for: .normal)
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
        collectionView.backgroundColor = .ypWhite
        collectionView.allowsMultipleSelection = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isScrollEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()
    
    private lazy var deadlinePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        picker.translatesAutoresizingMaskIntoConstraints = false
        if editTrackerHabit == nil {
            picker.minimumDate = Date()
        }
        return picker
    }()
    
    private lazy var assigneeTextField: UITextField = {
        let textField = UITextField()
        textField.indent(size: 16)
        textField.placeholder = "Ответственное лицо"
        textField.textColor = .ypBlack
        textField.backgroundColor = .ypWhite
        textField.layer.cornerRadius = 16
        textField.font = .systemFont(ofSize: 17)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.layer.borderWidth = 2
        textField.layer.borderColor = UIColor.ypBlue.cgColor
        textField.delegate = self
        return textField
    }()
    
    private lazy var assigneeStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [assigneeTextField, errorAssigneeLabel])
        stackView.distribution = .fill
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var detailsTextView: PlaceholderTextView = {
        let textView = PlaceholderTextView()
        textView.font = .systemFont(ofSize: 17)
        textView.backgroundColor = .ypWhite
        textView.layer.cornerRadius = 16
        textView.layer.borderWidth = 2
        textView.layer.borderColor = UIColor.ypBlue.cgColor
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.delegate = self
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.placeholder = "Подробное описание задачи..."
        if #available(iOS 13.0, *) {
            textView.placeholderColor = .placeholderText
        } else {
            textView.placeholderColor = .lightGray
        }
        return textView
    }()
    
    private lazy var attachButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(systemName: "paperclip")?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = .ypBlue
        button.setTitle(" Прикрепить вложения", for: .normal)
        button.setTitleColor(.ypBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(attachButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var deadlineLabel: UILabel = {
        let label = UILabel()
        label.text = "Крайний срок:"
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()
    
    private lazy var deadlineStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [deadlineLabel, deadlinePicker])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private var attachmentsStack: UIStackView?
    
    // MARK: - Lifecycle
    
    private var deadlineTimer: Timer?
    private var attachments: [Attachment] = []
    
    // Добавляем свойство для хранения constraint
    private var deadlineStackTopConstraint: NSLayoutConstraint?
    
    private var presentedImageVC: UIViewController? = nil
    
    // --- Для автокомплита assignee ---
    struct UserSearchEntry {
        let userId: String
        let email: String
        let tag: String?
        let name: String?
        let surname: String?
        
        var searchVariants: [String] {
            var variants = [email]
            if let tag = tag, !tag.isEmpty { variants.append(tag) }
            if let name = name, let surname = surname, !name.isEmpty, !surname.isEmpty {
                variants.append("\(name) \(surname)")
            }
            if let name = name, !name.isEmpty { variants.append(name) }
            if let surname = surname, !surname.isEmpty { variants.append(surname) }
            return variants
        }
    }

    // --- Массив для хранения всех пользователей ---
    private var allUsers: [UserSearchEntry] = []
    
    private var filteredUsers: [UserSearchEntry] = []
    private var assigneeSuggestionsTableView: UITableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configViews()
        configConstraints()
        clearDataStorege()
        deadlinePicker.addTarget(self, action: #selector(deadlineChanged), for: .valueChanged)
        if let _ = editTrackerHabit, let _ = editCategoryHabit, let daysLeft = deadlineDaysLeft {
            trackerEditing(daysLeft: daysLeft)
        }
        analyticsService.report(event: .open, params: ["Screen" : "NewHabit"])
        completedDaysLabel.textColor = .label
        updateDeadlineLabel()
        loadAllUsersForAssignee()
        setupAssigneeAutocompleteTable()
        assigneeTextField.addTarget(self, action: #selector(assigneeTextChanged), for: .editingChanged)
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
        // Для assignee
        let assigneeCount = assigneeTextField.text?.count ?? 0
        errorAssigneeLabel.isHidden = assigneeCount < assigneeCharacterLimit
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
        dismiss(animated: true)
    }
    
    @objc
    private func update() {
        guard let newTracker = collectingDataForTheTracker(newTracker: false) else { return }
        let categoryTracker = creatingTrackersModel[0].subTitleLabel
        delegateEdit?.trackerUpdate(newTracker, category: categoryTracker)
        analyticsService.report(event: .click, params: ["Screen" : "NewHabit", "Item" : Items.updateTracker.rawValue])
        dismiss(animated: true)
    }
    
    @objc private func deadlineChanged() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let deadlineDay = calendar.startOfDay(for: deadlinePicker.date)
        let daysLeft = calendar.dateComponents([.day], from: today, to: deadlineDay).day ?? 0
        let deadlineText = formatDeadlineDaysLeft(daysLeft)
        if deadlineText.hasPrefix("[overdue]") {
            completedDaysLabel.text = String(deadlineText.dropFirst(9))
            completedDaysLabel.textColor = .systemRed
        } else {
            completedDaysLabel.text = deadlineText
            completedDaysLabel.textColor = .label
        }
    }
    
    @objc private func attachButtonTapped() {
        let actionSheet = UIAlertController(title: "Добавить вложение", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Фото", style: .default) { _ in self.presentImagePicker(type: .photo) })
        actionSheet.addAction(UIAlertAction(title: "Видео", style: .default) { _ in self.presentImagePicker(type: .video) })
        actionSheet.addAction(UIAlertAction(title: "Файл", style: .default) { _ in self.presentDocumentPicker() })
        actionSheet.addAction(UIAlertAction(title: "Ссылка", style: .default) { _ in self.presentLinkAlert() })
        actionSheet.addAction(UIAlertAction(title: "Код", style: .default) { _ in self.presentCodeAlert() })
        actionSheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(actionSheet, animated: true)
    }
    
    private func presentImagePicker(type: AttachmentType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        if #available(iOS 14.0, *) {
            picker.mediaTypes = type == .photo ? [UTType.image.identifier] : [UTType.movie.identifier]
        } else {
            picker.mediaTypes = type == .photo ? [kUTTypeImage as String] : [kUTTypeMovie as String]
        }
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    private func presentDocumentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func presentLinkAlert() {
        let alert = UIAlertController(title: "Вставьте ссылку", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "https://example.com" }
        alert.addAction(UIAlertAction(title: "Добавить", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            // Проверяем, что текст похож на URL
            if let url = URL(string: text), UIApplication.shared.canOpenURL(url) {
                let attachment = Attachment(type: .link, url: url, text: text)
                self?.attachments.append(attachment)
                self?.updateAttachmentsView()
            } else {
                // Если не похоже на URL, показываем ошибку
                let errorAlert = UIAlertController(title: "Ошибка", message: "Введите корректную ссылку", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(errorAlert, animated: true)
            }
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    private func presentCodeAlert() {
        let alert = UIAlertController(title: "Вставьте код", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Ваш код..." }
        alert.addAction(UIAlertAction(title: "Добавить", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            let attachment = Attachment(type: .code, text: text)
            self?.attachments.append(attachment)
            self?.updateAttachmentsView()
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    private func updateAttachmentsView() {
        attachmentsStack?.removeFromSuperview()
        deadlineStackTopConstraint?.isActive = false
        if !attachments.isEmpty {
            let stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = 8
            stack.translatesAutoresizingMaskIntoConstraints = false
            for (index, att) in attachments.enumerated() {
                let hStack = UIStackView()
                hStack.axis = .horizontal
                hStack.spacing = 8
                hStack.isUserInteractionEnabled = true
                hStack.tag = index
                // Кнопка удаления
                let deleteButton = UIButton(type: .system)
                deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
                deleteButton.tintColor = .ypRed
                deleteButton.tag = index
                deleteButton.addTarget(self, action: #selector(deleteAttachment(_:)), for: .touchUpInside)
                deleteButton.widthAnchor.constraint(equalToConstant: 22).isActive = true
                deleteButton.heightAnchor.constraint(equalToConstant: 22).isActive = true
                // Иконка типа вложения
                let icon = UIImageView()
                icon.contentMode = .scaleAspectFit
                icon.tintColor = .ypBlue
                switch att.type {
                case .photo: icon.image = UIImage(systemName: "photo")
                case .video: icon.image = UIImage(systemName: "video")
                case .file: icon.image = UIImage(systemName: "doc")
                case .link: icon.image = UIImage(systemName: "link")
                case .code: icon.image = UIImage(systemName: "chevron.left.slash.chevron.right")
                case .other: icon.image = UIImage(systemName: "questionmark")
                }
                icon.widthAnchor.constraint(equalToConstant: 22).isActive = true
                icon.heightAnchor.constraint(equalToConstant: 22).isActive = true
                // Текст вложения
                let label = UILabel()
                label.font = .systemFont(ofSize: 15)
                label.textColor = .label
                label.text = att.fileName ?? att.text ?? att.url?.lastPathComponent ?? att.url?.absoluteString ?? "Вложение"
                // Добавляем элементы
                hStack.addArrangedSubview(deleteButton)
                hStack.addArrangedSubview(icon)
                hStack.addArrangedSubview(label)
                // Добавляем tap gesture для просмотра вложения
                let tap = UITapGestureRecognizer(target: self, action: #selector(attachmentTapped(_:)))
                hStack.addGestureRecognizer(tap)
                stack.addArrangedSubview(hStack)
            }
            contentView.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: attachButton.bottomAnchor, constant: 8),
                stack.leadingAnchor.constraint(equalTo: attachButton.leadingAnchor),
                stack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16)
            ])
            attachmentsStack = stack
            deadlineStackTopConstraint = deadlineStack.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 16)
        } else {
            deadlineStackTopConstraint = deadlineStack.topAnchor.constraint(equalTo: attachButton.bottomAnchor, constant: 16)
        }
        deadlineStackTopConstraint?.isActive = true
    }
    
    @objc private func deleteAttachment(_ sender: UIButton) {
        let index = sender.tag
        if index < attachments.count {
            attachments.remove(at: index)
            updateAttachmentsView()
        }
    }
    
    @objc private func attachmentTapped(_ sender: UITapGestureRecognizer) {
        guard let hStack = sender.view as? UIStackView else { return }
        let index = hStack.tag
        if index < attachments.count {
            viewAttachmentContent(attachments[index])
        }
    }
    
    // MARK: - Private methods
    private func collectingDataForTheTracker(newTracker: Bool) -> Tracker? {
        guard let text = nameTrackerTextField.text,
              let selectedEmojiIndexPath = isSelectedEmoji,
              let selectedColorIndexPath = isSelectedColor else { return nil }
        let emoji = emojiList[selectedEmojiIndexPath.row]
        let color = colors[selectedColorIndexPath.row]
        let deadline = deadlinePicker.date
        let statusTitle = creatingTrackersModel[1].subTitleLabel
        let status = statusOptions.first(where: { $0.1 == statusTitle })?.0 ?? "created"
        let assignee = assigneeTextField.text ?? ""
        let details = detailsTextView.text
        if newTracker {
            return Tracker(
                id: UUID(),
                name: text,
                color: color,
                emoji: emoji,
                isPinned: false,
                createdAt: Date(),
                deadline: deadline,
                isIrregular: false,
                status: status,
                assignee: assignee,
                pinnedAt: nil,
                details: details,
                attachments: attachments.isEmpty ? nil : attachments
            )
        } else {
            guard let editTracker = editTrackerHabit else { return nil }
            return Tracker(
                id: editTracker.id,
                name: text,
                color: color,
                emoji: emoji,
                isPinned: editTracker.isPinned,
                createdAt: editTracker.createdAt,
                deadline: deadline,
                isIrregular: editTracker.isIrregular,
                status: status,
                assignee: assignee,
                pinnedAt: editTracker.pinnedAt,
                details: details,
                attachments: attachments.isEmpty ? nil : attachments
            )
        }
    }
    
    private func trackerEditing(daysLeft: Int) {
        guard let trackerForEditing = editTrackerHabit else { return }
        guard let categiryForEditing = editCategoryHabit else { return }
        newHabitLabel.text = NSLocalizedString("editing", comment: "editing")
        completedDaysLabel.isHidden = false
        creatingButton.setTitle(NSLocalizedString("save", comment: "save"), for: .normal)
        creatingButton.addTarget(self, action: #selector(self.update), for: .touchUpInside)
        let deadlineText = standardEditDeadline(daysLeft: daysLeft)
        if deadlineText.hasPrefix("[overdue]") {
            completedDaysLabel.text = String(deadlineText.dropFirst(9))
            completedDaysLabel.textColor = .systemRed
        } else {
            completedDaysLabel.text = deadlineText
            completedDaysLabel.textColor = .label
        }
        nameTrackerTextField.text = trackerForEditing.name
        assigneeTextField.text = trackerForEditing.assignee
        detailsTextView.text = trackerForEditing.details
        
        // Загружаем вложения
        if let existingAttachments = trackerForEditing.attachments {
            attachments = existingAttachments
            updateAttachmentsView()
        }
        
        updateSubitle(nameSubitle: categiryForEditing)
        if let statusTuple = statusOptions.first(where: { $0.0 == trackerForEditing.status }) {
            creatingTrackersModel[1].subTitleLabel = statusTuple.1
        } else {
            creatingTrackersModel[1].subTitleLabel = "Создана"
        }
        if let emojiIndex = emojiList.firstIndex(of: trackerForEditing.emoji) {
            let emojieIndexPath = IndexPath(row: emojiIndex, section: 0)
            collectionView.selectItem(at: emojieIndexPath, animated: false, scrollPosition: [])
            collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: emojieIndexPath)
        }
        if let colorIndex = colors.firstIndex(where: { $0 == trackerForEditing.color }) {
            let colorIndexPath = IndexPath(row: colorIndex, section: 1)
            isSelectedColor = colorIndexPath
            collectionView.reloadData()
        }
        deadlinePicker.date = trackerForEditing.deadline ?? Date()
        updateCreatingButton()
    }
    
    private func standardEditDeadline(daysLeft: Int) -> String {
        let deadline = deadlinePicker.date
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: deadline)
        
        // Если статус "done", всегда показываем "Задача завершена"
        if let tracker = editTrackerHabit, tracker.status == "done" {
            return "Задача завершена"
        }
        
        if daysLeft == 0 {
            if deadline < Date() {
                return "Просрочено сегодня"
            } else {
                return "Дедлайн сегодня в \(timeString)"
            }
        } else if daysLeft == 1 {
            return "До дедлайна: 1 день"
        } else if daysLeft > 1 {
            return "До дедлайна: \(daysLeft) " + declensionDays(daysLeft)
        } else if daysLeft < 0 {
            let overdueDays = abs(daysLeft)
            return "Просрочено на \(overdueDays) " + declensionDays(overdueDays)
        } else {
            return ""
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
    
    private func formatDeadlineDaysLeft(_ days: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: deadlinePicker.date)
        if days == 0 {
            return "Дедлайн сегодня в \(timeString)"
        } else if days > 10 && days < 20 {
            return "До дедлайна: \(days) дней"
        } else if days > 0 {
            switch days % 10 {
            case 1:
                return "До дедлайна: \(days) день"
            case 2, 3, 4:
                return "До дедлайна: \(days) дня"
            default:
                return "До дедлайна: \(days) дней"
            }
        } else if days < 0 {
            let overdueDays = abs(days)
            return "[overdue]Просрочено на \(overdueDays) " + declensionDays(overdueDays)
        } else {
            return ""
        }
    }
    
    private func updateCreatingButton() {
        let categoryForActiveButton = creatingTrackersModel[0].subTitleLabel
        guard let selectedEmojiIndexPathHabbit = isSelectedEmoji else { return }
        guard let selectedColorIndexPathHabbit = isSelectedColor else { return }
        creatingButton.isEnabled = nameTrackerTextField.text?.isEmpty == false && categoryForActiveButton.isEmpty == false && selectedEmojiIndexPathHabbit.isEmpty == false && selectedColorIndexPathHabbit.isEmpty == false
        if creatingButton.isEnabled {
            creatingButton.backgroundColor = .ypBlack
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
        view.backgroundColor = .ypWhite
        view.addSubview(newHabitLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackViewForTextField)
        contentView.addSubview(tableView)
        contentView.addSubview(assigneeStackView)
        contentView.addSubview(detailsTextView)
        contentView.addSubview(attachButton)
        contentView.addSubview(deadlineStack)
        contentView.addSubview(collectionView)
        contentView.addSubview(cancelButton)
        contentView.addSubview(creatingButton)
        contentView.addSubview(completedDaysLabel)
        tableView.backgroundColor = .ypWhite
    }
    
    private func configConstraints() {
        let nameTrackerTextFieldConstant: CGFloat = editTrackerHabit == nil ? 28 : 106
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
            errorAssigneeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            tableView.topAnchor.constraint(equalTo: stackViewForTextField.bottomAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            tableView.heightAnchor.constraint(equalToConstant: 150),
            assigneeStackView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 24),
            assigneeStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            assigneeStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            assigneeStackView.heightAnchor.constraint(equalToConstant: 75),
            detailsTextView.topAnchor.constraint(equalTo: assigneeStackView.bottomAnchor, constant: 16),
            detailsTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailsTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detailsTextView.heightAnchor.constraint(equalToConstant: 100),
            attachButton.topAnchor.constraint(equalTo: detailsTextView.bottomAnchor, constant: 8),
            attachButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            attachButton.heightAnchor.constraint(equalToConstant: 32),
            deadlineStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            deadlineStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            collectionView.topAnchor.constraint(equalTo: deadlineStack.bottomAnchor, constant: 32),
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
        // Устанавливаем начальный constraint для deadlineStack
        deadlineStackTopConstraint = deadlineStack.topAnchor.constraint(equalTo: attachButton.bottomAnchor, constant: 16)
        deadlineStackTopConstraint?.isActive = true
    }
    
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
        if let _ = editTrackerHabit, let _ = editCategoryHabit, let daysLeft = deadlineDaysLeft {
            let deadlineText = standardEditDeadline(daysLeft: daysLeft)
            if deadlineText.contains("Просрочено") {
                completedDaysLabel.text = deadlineText
                completedDaysLabel.textColor = .systemRed
            } else {
                completedDaysLabel.text = deadlineText
                completedDaysLabel.textColor = .label
            }
        }
    }
    
    // Добавляем метод для просмотра вложений
    fileprivate func viewAttachmentContent(_ attachment: Attachment) {
        switch attachment.type {
        case .photo:
            if let url = attachment.url {
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFit
                imageView.backgroundColor = .black
                imageView.isUserInteractionEnabled = true
                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    imageView.image = image
                    let viewController = UIViewController()
                    viewController.view.backgroundColor = .black
                    viewController.modalPresentationStyle = .fullScreen
                    // Затемнённый фон для закрытия по тапу
                    let bgTap = UITapGestureRecognizer(target: self, action: #selector(dismissFullScreen))
                    viewController.view.addGestureRecognizer(bgTap)
                    // Добавляем imageView
                    imageView.translatesAutoresizingMaskIntoConstraints = false
                    viewController.view.addSubview(imageView)
                    NSLayoutConstraint.activate([
                        imageView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
                        imageView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
                        imageView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
                        imageView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor)
                    ])
                    // Кнопка закрытия
                    let closeButton = UIButton(type: .system)
                    closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
                    closeButton.tintColor = .white
                    closeButton.translatesAutoresizingMaskIntoConstraints = false
                    closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.2)
                    closeButton.layer.cornerRadius = 24
                    closeButton.clipsToBounds = true
                    viewController.view.addSubview(closeButton)
                    NSLayoutConstraint.activate([
                        closeButton.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor, constant: 24),
                        closeButton.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -24),
                        closeButton.widthAnchor.constraint(equalToConstant: 48),
                        closeButton.heightAnchor.constraint(equalToConstant: 48)
                    ])
                    closeButton.addTarget(self, action: #selector(dismissFullScreen), for: .touchUpInside)
                    // Свайп вниз для закрытия
                    let pan = UIPanGestureRecognizer(target: self, action: #selector(handleImagePan(_:)))
                    viewController.view.addGestureRecognizer(pan)
                    present(viewController, animated: true)
                }
            }
            
        case .video:
            if let url = attachment.url {
                let player = AVPlayer(url: url)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                present(playerViewController, animated: true) {
                    player.play()
                }
            }
            
        case .file:
            if let url = attachment.url {
                let documentViewController = UIDocumentInteractionController(url: url)
                documentViewController.delegate = self
                documentViewController.presentPreview(animated: true)
            }
            
        case .link:
            if let url = attachment.url {
                UIApplication.shared.open(url)
            }
            
        case .code:
            if let text = attachment.text {
                let alert = UIAlertController(title: "Код", message: text, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Копировать", style: .default) { _ in
                    UIPasteboard.general.string = text
                })
                alert.addAction(UIAlertAction(title: "Закрыть", style: .cancel))
                present(alert, animated: true)
            }
            
        case .other:
            break
        }
    }

    @objc private func dismissFullScreen() {
        if let presented = presentedViewController {
            presented.dismiss(animated: true)
        } else if let presented = presentedImageVC {
            presented.dismiss(animated: true)
            presentedImageVC = nil
        }
    }

    @objc private func handleImagePan(_ gesture: UIPanGestureRecognizer) {
        guard let vc = presentedViewController else { return }
        let translation = gesture.translation(in: vc.view)
        if gesture.state == .changed {
            vc.view.transform = CGAffineTransform(translationX: 0, y: translation.y)
        } else if gesture.state == .ended {
            if translation.y > 120 {
                vc.dismiss(animated: true)
            } else {
                UIView.animate(withDuration: 0.2) {
                    vc.view.transform = .identity
                }
            }
        }
    }

    private func loadAllUsersForAssignee() {
        let db = Firestore.firestore()
        db.collection("users").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            guard let documents = snapshot?.documents, error == nil else { return }
            self.allUsers = documents.compactMap { doc in
                let data = doc.data()
                return UserSearchEntry(
                    userId: doc.documentID,
                    email: data["email"] as? String ?? "",
                    tag: data["tag"] as? String,
                    name: data["name"] as? String,
                    surname: data["surname"] as? String
                )
            }
        }
    }

    private func setupAssigneeAutocompleteTable() {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isHidden = true
        tableView.layer.cornerRadius = 12
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.ypBlue.cgColor
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AssigneeSuggestionCell")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: assigneeTextField.bottomAnchor, constant: 2),
            tableView.leadingAnchor.constraint(equalTo: assigneeTextField.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: assigneeTextField.trailingAnchor),
            tableView.heightAnchor.constraint(equalToConstant: 150)
        ])
        assigneeSuggestionsTableView = tableView
    }

    @objc private func assigneeTextChanged() {
        let input = assigneeTextField.text?.lowercased() ?? ""
        if input.isEmpty {
            filteredUsers = []
            assigneeSuggestionsTableView?.isHidden = true
            assigneeSuggestionsTableView?.reloadData()
            return
        }
        filteredUsers = allUsers.filter { user in
            user.searchVariants.contains { $0.lowercased().contains(input) }
        }
        assigneeSuggestionsTableView?.isHidden = filteredUsers.isEmpty
        assigneeSuggestionsTableView?.reloadData()
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
                creatingTrackersModel[0].subTitleLabel = NSLocalizedString("everyDay", comment: "everyDay")
            } else {
                creatingTrackersModel[0].subTitleLabel = days.joined(separator: ", ")
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
}

// MARK: - UITextFieldDelegate

extension NewHabitViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == assigneeTextField {
            let currentText = textField.text ?? ""
            let newLength = currentText.count + string.count - range.length
            errorAssigneeLabel.isHidden = newLength < assigneeCharacterLimit
            return newLength <= assigneeCharacterLimit
        }
        let textFieldText = textField.text ?? ""
        let newLength = textFieldText.count + string.count - range.length
        return newLength <= characterLimitInField
    }
}

// MARK: - CreatingHabitViewController

extension NewHabitViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == assigneeSuggestionsTableView {
            return filteredUsers.count
        }
        return creatingTrackersModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == assigneeSuggestionsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AssigneeSuggestionCell", for: indexPath)
            let user = filteredUsers[indexPath.row]
            var display = ""
            if let tag = user.tag, !tag.isEmpty {
                display += tag
            }
            if let name = user.name, !name.isEmpty {
                display += " " + name
            }
            if let surname = user.surname, !surname.isEmpty {
                display += " " + surname
            }
            cell.textLabel?.text = display.trimmingCharacters(in: .whitespaces)
            cell.textLabel?.font = .systemFont(ofSize: 15)
            return cell
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewTableCell", for: indexPath) as? NewTableCell else { return UITableViewCell() }
        let data = creatingTrackersModel[indexPath.row]
        if indexPath.row == 1 {
            // статус
            let color = statusOptions.first(where: { $0.1 == data.subTitleLabel })?.2 ?? UIColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1)
            cell.configureCell(title: data.titleLabelText, subTitle: data.subTitleLabel, subTitleColor: color)
        } else {
            cell.configureCell(title: data.titleLabelText, subTitle: data.subTitleLabel)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == assigneeSuggestionsTableView {
            let user = filteredUsers[indexPath.row]
            if let tag = user.tag, !tag.isEmpty {
                assigneeTextField.text = tag
            } else {
                assigneeTextField.text = ""
            }
            assigneeSuggestionsTableView?.isHidden = true
            assigneeTextField.resignFirstResponder()
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            let categoryViewController = TrackerCategoryViewController()
            let categoryViewModel = TrackerCategoryViewModel()
            categoryViewController.initialize(viewModel: categoryViewModel)
            categoryViewModel.delegateHabbit = self
            let navigationController = UINavigationController(rootViewController: categoryViewController)
            present(navigationController, animated: true)
        } else if indexPath.row == 1 {
            // статус
            let alertController = UIAlertController(title: "Выберите статус", message: nil, preferredStyle: .actionSheet)
            for (_, title, _) in statusOptions {
                let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                    self?.creatingTrackersModel[1].subTitleLabel = title
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                }
                alertController.addAction(action)
            }
            let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
            alertController.addAction(cancelAction)
            present(alertController, animated: true)
        }
    }
}

// MARK: - UICollectionViewDelegate

extension NewHabitViewController: UICollectionViewDelegate {
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
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as? SupplementaryView else { return UICollectionReusableView()}
        view.titleLabel.text = indexPath.section == 0 ? NSLocalizedString("emoji", comment: "emoji") : NSLocalizedString("color", comment: "color")
        return view
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension NewHabitViewController: UICollectionViewDelegateFlowLayout {
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
        return CGSize(width: collectionView.frame.width, height: 40)
    }
}

// MARK: - UITextViewDelegate

extension NewHabitViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if let placeholderTextView = textView as? PlaceholderTextView {
            placeholderTextView.setNeedsDisplay()
        }
    }
    func textViewDidBeginEditing(_ textView: UITextView) {}
    func textViewDidEndEditing(_ textView: UITextView) {}
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate

extension NewHabitViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let imageUrl = info[.imageURL] as? URL {
            let attachment = Attachment(type: .photo, url: imageUrl, fileName: imageUrl.lastPathComponent)
            attachments.append(attachment)
        } else if let image = info[.originalImage] as? UIImage {
            // Сохраняем изображение во временный файл
            if let data = image.jpegData(compressionQuality: 0.95) {
                let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                try? data.write(to: tempUrl)
                let attachment = Attachment(type: .photo, url: tempUrl, fileName: tempUrl.lastPathComponent)
                attachments.append(attachment)
            }
        } else if let videoUrl = info[.mediaURL] as? URL {
            let attachment = Attachment(type: .video, url: videoUrl, fileName: videoUrl.lastPathComponent)
            attachments.append(attachment)
        }
        updateAttachmentsView()
        picker.dismiss(animated: true)
    }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            let attachment = Attachment(type: .file, url: url, fileName: url.lastPathComponent)
            attachments.append(attachment)
        }
        updateAttachmentsView()
    }
}

// MARK: - UIDocumentInteractionControllerDelegate

extension NewHabitViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}
