//
//  TrackersViewController.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit

final class TrackerViewController: UIViewController, UICollectionViewDelegate, UISearchBarDelegate, UITextFieldDelegate {
    private let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhiteDay
        setNavigationBar()
    }
    
    func setNavigationBar() {
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.largeTitleDisplayMode = .always
            title = "Трекеры"

            let addButton = UIButton(type: .custom)
            if let iconImage = UIImage(named: "addTracker")?.withRenderingMode(.alwaysOriginal) {
                addButton.setImage(iconImage, for: .normal)
            }
            addButton.titleLabel?.font = UIFont(name: "SF Pro", size: 34)
            addButton.addTarget(
                self,
                action: #selector(addTrackerButtonTapped),
                for: .touchUpInside
            )

            addButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -20, bottom: 0, right: 0)

            let addButtonItem = UIBarButtonItem(customView: addButton)
            navigationItem.leftBarButtonItem = addButtonItem
            setDatePickerItem()
            searchController.searchBar.placeholder = "Поиск"
            searchController.obscuresBackgroundDuringPresentation = false
            navigationItem.searchController = searchController
            definesPresentationContext = true
            searchController.searchBar.delegate = self
            self.datePicker = datePicker
        }

        func setDatePickerItem() {
            datePicker.preferredDatePickerStyle = .compact
            datePicker.datePickerMode = .date
            datePicker.locale = Locale(identifier: "ru_RU")
            datePicker.calendar.firstWeekday = 2
            datePicker.translatesAutoresizingMaskIntoConstraints = false
            datePicker.clipsToBounds = true
            datePicker.layer.cornerRadius = 8
            datePicker.tintColor = .ypBlue
            datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yy"

            dateFormatter.locale = Locale(identifier: "ru_RU")

            datePicker.locale = dateFormatter.locale
            datePicker.calendar = dateFormatter.calendar

            let currentDate = Date()
            let calendar = Calendar(identifier: .gregorian)
            var dateComponents = DateComponents()
            dateComponents.year = -100
            let maxDate = calendar.date(byAdding: dateComponents, to: currentDate)
            dateComponents.year = 100
            let minDate = calendar.date(byAdding: dateComponents, to: currentDate)
            datePicker.minimumDate = maxDate
            datePicker.maximumDate = minDate

            let widthConstraint = NSLayoutConstraint(
                item: datePicker,
                attribute: .width,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1.0,
                constant: 120
            )

            datePicker.addConstraint(widthConstraint)

            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)
        }

        private lazy var dateLabel: UILabel = {
            let label = UILabel()
            label.backgroundColor = .ypLightGray
            label.font = UIFont(name: "SF Pro", size: 17)
            label.textAlignment = .center
            label.textColor = .ypBlackDay
            label.translatesAutoresizingMaskIntoConstraints = false
            label.clipsToBounds = true
            label.layer.cornerRadius = 8
            label.layer.zPosition = 1000
            return label
        }()

        private lazy var datePicker: UIDatePicker = {
            let pickerDate = UIDatePicker()
            pickerDate.preferredDatePickerStyle = .compact
            pickerDate.datePickerMode = .date
            pickerDate.locale = Locale(identifier: "ru_RU")
            pickerDate.calendar.firstWeekday = 2
            pickerDate.translatesAutoresizingMaskIntoConstraints = false
            pickerDate.clipsToBounds = true
            pickerDate.layer.cornerRadius = 8
            pickerDate.tintColor = .ypBlue
            pickerDate.addTarget(self, action: #selector(dateChanged), for: .valueChanged)

            return pickerDate
        }()

        private lazy var searchTextField: UISearchTextField = {
            let textField = UISearchTextField()
            textField.backgroundColor = .ypBackgroundDay
            textField.textColor = .ypBlackDay
            textField.font = UIFont.systemFont(ofSize: 17)
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.layer.cornerRadius = 10
            textField.heightAnchor.constraint(equalToConstant: 36).isActive = true

            let attributes = [
                NSAttributedString.Key.foregroundColor: UIColor.ypGray
            ]

            let attributedPlaceholder = NSAttributedString(
                string: "Поиск",
                attributes: attributes
            )

            textField.attributedPlaceholder = attributedPlaceholder
            textField.delegate = self

            return textField
        }()


        @objc private func addTrackerButtonTapped() {
            print("Добавляем трекер")
        }

        @objc private func dateChanged() {
            updateDateLabelTitle(with: datePicker.date)
        }

        private func formattedDate(from date: Date) -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yy"
            return dateFormatter.string(from: date)
        }

        private func updateDateLabelTitle(with date: Date) {
            let dateString = formattedDate(from: date)
            dateLabel.text = dateString
        }


}
