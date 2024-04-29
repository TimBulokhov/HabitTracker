//
//  ScheduleViewController.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit

// MARK: - enum DaysOfTheWeek

private enum DaysOfTheWeek: String, CaseIterable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
}

// MARK: - ScheduleViewController

final class ScheduleViewController: UIViewController {
    weak var delegate: NewHabitViewControllerDelegate?
    private let dataStorege = DataStorege.shared
    
    // MARK: - UiElements
    
    private var tableView: UITableView = .init()
    
    private lazy var scheduleLabel: UILabel = {
        let label = UILabel()
        label.text = "Schedule"
        label.textColor = .ypBlackDay
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton()
        button.setTitle("Ready", for: .normal)
        button.setTitleColor(.ypWhiteDay, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .ypBlackDay
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(self.actionsForButton), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configViews()
        configTableView()
        configConstraints()
    }
    
    // MARK: - Actions
    
    @objc
    func actionsForButton() {
        guard let daysInAWeek = sortedDayInWeek(weekDayArray: dataStorege.loadDaysInAWeek()) else { return }
        delegate?.updateDate(days: daysInAWeek)
        dismiss(animated: true)
    }
    
    // MARK: - Private methods
    
    private func sortedDayInWeek(weekDayArray: [String]) -> [String]?{
        let abbreviationDays: [String] = weekDayArray.compactMap { day in
            if let date = dateFormatter.date(from: day) {
                return dateFormatter.string(from: date)
            }
            return nil
        }
        return abbreviationDays
    }
    
    private func configTableView() {
        tableView.register(ScheduleCell.self, forCellReuseIdentifier: "ScheduleCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = .ypGray
        tableView.layer.cornerRadius = 16
        tableView.layer.masksToBounds = true
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tableView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func configViews() {
        view.backgroundColor = .ypWhiteDay
        view.addSubview(tableView)
        view.addSubview(scheduleLabel)
        view.addSubview(doneButton)
    }
    
    private func configConstraints() {
        NSLayoutConstraint.activate([
            scheduleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scheduleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 27),
            tableView.topAnchor.constraint(equalTo: scheduleLabel.bottomAnchor, constant: 30),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -70),
            doneButton.heightAnchor.constraint(equalToConstant: 60),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
}

// MARK: - ScheduleCellDelegate

extension ScheduleViewController: ScheduleCellDelegate {
    func didToogleSwitch(for day: String, switchActive: Bool) {
        if switchActive {
            dataStorege.saveDaysInAWeek(day)
        } else {
            guard let indexDay = searchDayIndex(day) else { return }
            dataStorege.removeDaysInAWeek(atIndex: indexDay)
        }
    }
    
    private func searchDayIndex(_ nameDay: String) -> Int? {
        if let index = dataStorege.loadDaysInAWeek().firstIndex(where: { $0 == nameDay }) {
            return index
        } else {
            return nil
        }
    }
}

// MARK: - UITableViewDelegate

extension ScheduleViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
}

// MARK: - UITableViewDataSource

extension ScheduleViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DaysOfTheWeek.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleCell", for: indexPath) as? ScheduleCell
        else { fatalError() }
        cell.delegate = self
        let day: String = DaysOfTheWeek.allCases[indexPath.row].rawValue
        let isSwitchOn = dataStorege.loadDaysInAWeek().contains(day)
        //cell.configureCell(with: day, isSwitchOn: isSwitchOn)
        cell.configureCell(with: day, isSwitchOn: isSwitchOn, cellIndex: indexPath.row, numberOfLines: DaysOfTheWeek.allCases.count)
        return cell
    }
}
