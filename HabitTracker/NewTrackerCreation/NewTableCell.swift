//
//  NewTableCell.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit

final class NewTableCell: UITableViewCell {
    
    // MARK: - UIElements
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .leading
        stackView.spacing = 2.0
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let categoryLabel: UILabel = {
        let trackerLabel = UILabel()
        trackerLabel.textColor = .ypBlackDay
        trackerLabel.textAlignment = .left
        trackerLabel.font = .systemFont(ofSize: 17, weight: .regular)
        return trackerLabel
    }()
    
    private let subTitleLabel: UILabel = {
        let subTitle = UILabel()
        subTitle.textColor = .ypGray
        subTitle.textAlignment = .left
        subTitle.font = .systemFont(ofSize: 17, weight: .regular)
        return subTitle
    }()
    
    // MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.accessoryType = .disclosureIndicator
        self.backgroundColor = .ypBackgroundDay
        configViews()
        configConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Methods
    
    func configureCell(title: String, subTitle: String) {
        categoryLabel.text = title
        subTitleLabel.text = subTitle
        subTitleLabel.isHidden = subTitle.isEmpty ? true: false
    }
    
    // MARK: - Private methods
    
    private func configViews() {
        stackView.addArrangedSubview(categoryLabel)
        stackView.addArrangedSubview(subTitleLabel)
        contentView.addSubview(stackView)
    }
    
    private func configConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            contentView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 14)
        ])
    }
}
