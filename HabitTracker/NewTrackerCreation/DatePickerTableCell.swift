import UIKit

final class DatePickerTableCell: UITableViewCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Дата и время"
        label.textColor = .ypBlack
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.minimumDate = Date()
        return picker
    }()

    private var onDateChanged: ((Date) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .ypWhite
        contentView.addSubview(titleLabel)
        contentView.addSubview(datePicker)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            datePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            datePicker.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            datePicker.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8)
        ])
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(date: Date, onDateChanged: @escaping (Date) -> Void) {
        datePicker.date = date
        self.onDateChanged = onDateChanged
    }

    @objc private func dateChanged() {
        onDateChanged?(datePicker.date)
    }
} 