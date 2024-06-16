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
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        return button
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
        backgroundCellView.backgroundColor = tracker.color
        accomplishedButton.backgroundColor = tracker.color
        descriptionLabel.text = tracker.name
        emojiLabel.text = tracker.emoji
        pinnedImage.isHidden = !tracker.isPinned
        self.trackerId = tracker.id
    }
    
    func completeTracker(days: Int, completed: Bool) {
        self.isCompletedToday = completed
        daysCounterLabel.text = formatDaysText(forDays: days)
        updatePlusButton(trackerCompleted: completed)
    }
    
    // MARK: - Private methods
    
    private func formatDaysText(forDays days: Int) -> String {
        let daysCounter = String.localizedStringWithFormat(NSLocalizedString("numberOfDay", comment: "numberOfDay"), days)
        return daysCounter
    }
    
    private func updatePlusButton(trackerCompleted: Bool) {
        let image: UIImage = (trackerCompleted ? UIImage(systemName: "checkmark") : UIImage(systemName: "plus"))!
        accomplishedButton.setImage(image, for: .normal)
        let buttonOpacity: Float = trackerCompleted ? 0.3 : 1
        accomplishedButton.layer.opacity = buttonOpacity
    }
    
    private func setupViews() {
        self.backgroundColor = .clear
        contentView.addSubview(backgroundCellView)
        contentView.addSubview(daysCounterLabel)
        contentView.addSubview(accomplishedButton)
        backgroundCellView.addSubview(emojiLabel)
        backgroundCellView.addSubview(descriptionLabel)
        backgroundCellView.addSubview(pinnedImage)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundCellView.topAnchor.constraint(equalTo: topAnchor),
            backgroundCellView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundCellView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundCellView.heightAnchor.constraint(equalToConstant: 90),
            
            emojiLabel.topAnchor.constraint(equalTo: backgroundCellView.topAnchor, constant: 12),
            emojiLabel.leadingAnchor.constraint(equalTo: backgroundCellView.leadingAnchor, constant: 12),
            emojiLabel.heightAnchor.constraint(equalToConstant: 24),
            emojiLabel.widthAnchor.constraint(equalToConstant: 24),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: backgroundCellView.leadingAnchor, constant: 12),
            descriptionLabel.trailingAnchor.constraint(equalTo: backgroundCellView.trailingAnchor, constant: -12),
            descriptionLabel.bottomAnchor.constraint(equalTo: backgroundCellView.bottomAnchor, constant: -12),
            
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
