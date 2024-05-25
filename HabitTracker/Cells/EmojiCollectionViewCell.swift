//
//  EmojiCollectionViewCell.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 25.05.2024.
//

import UIKit

final class EmojiCollectionViewCell: UICollectionViewCell {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 35)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        config()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private methods
    
    private func config() {
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate(
            [ titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
              titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)]
        )
    }
}
