//
//  TrackerCell.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit

protocol TrackerCellDelegate: AnyObject {
    func trackerCompleted(id: UUID)
    func trackerNotCompleted(id: UUID)
}

final class TrackerCell: UICollectionViewCell {
    weak var delegate: TrackerCellDelegate?
    private var isCompletedToday = false
    private var tracker: Tracker?
    private var trackerId: UUID?
    
    // MARK: - UiElements
    
    let backgroundCellView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        return view
    }()
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .white.withAlphaComponent(0.3)
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let assigneeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private lazy var pinnedImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "pinnedIcon")
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let daysCounterLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .ypBlack
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var accomplishedButton: UIButton = {
        let button = UIButton()
        button.tintColor = .ypWhite
        button.layer.cornerRadius = 17
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    
    @objc private func buttonAction() {
        guard let trackerId = trackerId else { return }
        if !isCompletedToday {
            delegate?.trackerCompleted(id: trackerId)
        } else {
            delegate?.trackerNotCompleted(id: trackerId)
        }
    }
    
    // MARK: - Methods
    
    func setupCell(tracker: Tracker) {
        self.tracker = tracker
        backgroundCellView.backgroundColor = tracker.color
        accomplishedButton.backgroundColor = tracker.color
        descriptionLabel.text = tracker.name
        emojiLabel.text = tracker.emoji
        pinnedImage.isHidden = !tracker.isPinned
        self.trackerId = tracker.id
        // Assignee
        if !tracker.assignee.isEmpty {
            assigneeLabel.text = tracker.assignee
            assigneeLabel.isHidden = false
        } else {
            assigneeLabel.text = nil
            assigneeLabel.isHidden = true
        }
        
        // Скрываем статус, если он пустой или nil
        if tracker.status.isEmpty {
            statusLabel.isHidden = true
        } else {
            statusLabel.isHidden = false
            // Set status text and color
            let statusText: String
            let statusColor: UIColor
            switch tracker.status {
            case "created":
                statusText = "Создана"
                statusColor = UIColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1)
            case "in_progress":
                statusText = "В процессе"
                statusColor = UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1)
            case "completed":
                statusText = "Выполнена"
                statusColor = UIColor(red: 66/255, green: 170/255, blue: 255/255, alpha: 1)
            case "testing":
                statusText = "Тестируется"
                statusColor = UIColor(red: 247/255, green: 148/255, blue: 60/255, alpha: 1)
            case "ready_for_release":
                statusText = "Готово к релизу"
                statusColor = UIColor(red: 0/255, green: 165/255, blue: 80/255, alpha: 1)
            case "done":
                statusText = "Завершена"
                statusColor = UIColor(red: 102/255, green: 0/255, blue: 153/255, alpha: 1)
            default:
                statusText = ""
                statusColor = .clear
            }
            statusLabel.text = statusText
            statusLabel.textColor = statusColor
        }
        
        if let deadline = tracker.deadline {
            if tracker.isIrregular {
                let text = irregularDeadlineText(deadline: deadline)
                daysCounterLabel.text = text.replacingOccurrences(of: "[done]", with: "")
                daysCounterLabel.textColor = text.contains("Событие завершено") ? .label : .label
            } else {
                let text = standardDeadlineText(deadline: deadline)
                daysCounterLabel.text = text.replacingOccurrences(of: "[overdue]", with: "")
                daysCounterLabel.textColor = text.contains("Просрочено") ? .systemRed : .label
            }
        } else {
            daysCounterLabel.text = ""
            daysCounterLabel.textColor = .label
        }
    }
    
    private func isIrregular(tracker: Tracker) -> Bool {
        // Считаем нерегулярным, если createdAt и deadline не совпадают по дню
        guard let createdAt = tracker.createdAt, let deadline = tracker.deadline else { return false }
        let calendar = Calendar.current
        return calendar.compare(createdAt, to: deadline, toGranularity: .day) != .orderedSame
    }
    
    private func standardDeadlineText(deadline: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let deadlineDay = calendar.startOfDay(for: deadline)
        let daysLeft = calendar.dateComponents([.day], from: today, to: deadlineDay).day ?? 0
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: deadline)
        
        // Если статус "done", всегда показываем "Задача завершена"
        if let currentTracker = tracker, currentTracker.status == "done" {
            return "Задача завершена"
        }
        
        if daysLeft == 0 {
            if deadline < Date() {
                return "Просрочено сегодня"
            } else {
                return "Дедлайн сегодня в \(timeString)"
            }
        } else if daysLeft == 1 {
            return "Дедлайн завтра в \(timeString)"
        } else if daysLeft > 1 {
            return "Дедлайн через \(daysLeft) " + declensionDays(daysLeft) + " в \(timeString)"
        } else if daysLeft < 0 {
            let overdueDays = abs(daysLeft)
            return "Просрочено на \(overdueDays) " + declensionDays(overdueDays)
        } else {
            return ""
        }
    }
    
    private func irregularDeadlineText(deadline: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let deadlineDay = calendar.startOfDay(for: deadline)
        let daysLeft = calendar.dateComponents([.day], from: today, to: deadlineDay).day ?? 0
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: deadline)
        if daysLeft == 0 {
            if deadline < Date() {
                return "Событие завершено"
            } else {
                return "Сегодня в \(timeString)"
            }
        } else if daysLeft == 1 {
            return "Завтра в \(timeString)"
        } else if daysLeft > 1 {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale.current
            dateFormatter.setLocalizedDateFormatFromTemplate("d MMMM")
            let dateString = dateFormatter.string(from: deadline)
            return "\(dateString) в \(timeString)"
        } else if daysLeft < 0 {
            return "Событие завершено"
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        pinnedImage.isHidden = true
        isCompletedToday = false
        trackerId = nil
        backgroundCellView.backgroundColor = .clear
        accomplishedButton.backgroundColor = .clear
        descriptionLabel.text = nil
        emojiLabel.text = nil
        daysCounterLabel.text = nil
        statusLabel.text = nil
        assigneeLabel.text = nil
        assigneeLabel.isHidden = true
    }
    
    // MARK: - Private methods
    
    private func setupViews() {
        self.backgroundColor = .clear
        contentView.addSubview(backgroundCellView)
        contentView.addSubview(daysCounterLabel)
        contentView.addSubview(accomplishedButton)
        backgroundCellView.addSubview(emojiLabel)
        backgroundCellView.addSubview(descriptionLabel)
        backgroundCellView.addSubview(assigneeLabel)
        backgroundCellView.addSubview(pinnedImage)
        backgroundCellView.addSubview(statusLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundCellView.topAnchor.constraint(equalTo: topAnchor),
            backgroundCellView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundCellView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundCellView.heightAnchor.constraint(equalToConstant: 110),
            
            emojiLabel.topAnchor.constraint(equalTo: backgroundCellView.topAnchor, constant: 12),
            emojiLabel.leadingAnchor.constraint(equalTo: backgroundCellView.leadingAnchor, constant: 12),
            emojiLabel.heightAnchor.constraint(equalToConstant: 24),
            emojiLabel.widthAnchor.constraint(equalToConstant: 24),
            
            statusLabel.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: backgroundCellView.leadingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: backgroundCellView.trailingAnchor, constant: -12),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: backgroundCellView.leadingAnchor, constant: 12),
            descriptionLabel.trailingAnchor.constraint(equalTo: backgroundCellView.trailingAnchor, constant: -12),
            descriptionLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            
            assigneeLabel.leadingAnchor.constraint(equalTo: backgroundCellView.leadingAnchor, constant: 12),
            assigneeLabel.trailingAnchor.constraint(equalTo: backgroundCellView.trailingAnchor, constant: -12),
            assigneeLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 4),
            assigneeLabel.heightAnchor.constraint(equalToConstant: 18),
            
            daysCounterLabel.topAnchor.constraint(equalTo: backgroundCellView.bottomAnchor, constant: 16),
            daysCounterLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            
            accomplishedButton.topAnchor.constraint(equalTo: backgroundCellView.bottomAnchor, constant: 8),
            accomplishedButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            accomplishedButton.heightAnchor.constraint(equalToConstant: 34),
            accomplishedButton.widthAnchor.constraint(equalToConstant: 34),
            
            pinnedImage.topAnchor.constraint(equalTo: backgroundCellView.topAnchor, constant: 12),
            pinnedImage.trailingAnchor.constraint(equalTo: backgroundCellView.trailingAnchor, constant: -12),
            pinnedImage.heightAnchor.constraint(equalToConstant: 12),
            pinnedImage.widthAnchor.constraint(equalToConstant: 8),
        ])
    }
}
