//
//  FilterViewController.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 09.06.2024.
//

import UIKit

enum FilterName: String, CaseIterable {
    case tasksByDate = "Задачи по дате"
    case completed = "Выполненные"
    case created = "Созданные"
    case inProgress = "В работе"
    case testing = "Тестирование"
    case readyForRelease = "Готово к релизу"
    case overdue = "Просроченные"
    case completedTrackers = "Завершённые"
    case pinned = "Закреплённые"
}

protocol FilterViewControllerProtocol: AnyObject {
    func filterSelected(filter: FilterName?)
}

// MARK: - FilterViewController

final class FilterViewController: UIViewController {
    var selectedFilter: FilterName?
    weak var delegate: FilterViewControllerProtocol?
    // Группируем фильтры по секциям
    private let filterSections: [[FilterName]] = [
        [.tasksByDate], // По дате
        [.completed, .created, .inProgress, .testing, .readyForRelease, .pinned], // По статусу
        [.overdue, .completedTrackers] // По срокам
    ]
    private let sectionTitles = ["По дате", "По статусу", "По срокам"]
    private let analyticsService = AnalyticsService()
    
    // MARK: - UiElements
    
    private lazy var filterLabel: UILabel = {
        let trackerLabel = UILabel()
        trackerLabel.text = NSLocalizedString("filterButton", comment: "filterButton")
        trackerLabel.textColor = .ypBlack
        trackerLabel.font = .systemFont(ofSize: 16, weight: .medium)
        trackerLabel.translatesAutoresizingMaskIntoConstraints = false
        return trackerLabel
    }()
    
    private lazy var resetButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Сбросить"
        config.baseForegroundColor = .systemRed
        config.baseBackgroundColor = .clear
        config.cornerStyle = .medium
        config.background.strokeColor = .systemRed
        config.background.strokeWidth = 1.5
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var attr = attr
            attr.font = .boldSystemFont(ofSize: 17)
            return attr
        }
        button.configuration = config
        button.addTarget(self, action: #selector(resetFilters), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.layer.cornerRadius = 16
        tableView.layer.masksToBounds = true
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .ypWhite
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configViews()
        configConstraints()
        tableView.reloadData()
        analyticsService.report(event: .open, params: ["Screen" : "FilterView"])
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        analyticsService.report(event: .close, params: ["Screen" : "FilterView"])
    }
    
    // MARK: - Actions
    
    @objc private func resetFilters() {
        print("[DEBUG] Кнопка сбросить нажата")
        selectedFilter = nil
        delegate?.filterSelected(filter: nil)
        dismiss(animated: true)
    }
    
    // MARK: - Private methods
    
    private func configViews() {
        view.backgroundColor = .ypWhite
        view.addSubview(filterLabel)
        view.addSubview(tableView)
        view.addSubview(resetButton)
    }
    
    private func configConstraints() {
        NSLayoutConstraint.activate([
            filterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 27),
            tableView.topAnchor.constraint(equalTo: filterLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.heightAnchor.constraint(equalToConstant: 600),
            tableView.bottomAnchor.constraint(equalTo: resetButton.topAnchor, constant: -24),
            resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resetButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            resetButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -24)
        ])
        tableView.isScrollEnabled = true
    }
}

// MARK: - UITableViewDataSource

extension FilterViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return filterSections.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterSections[section].count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let filter = filterSections[indexPath.section][indexPath.row]
        var filterText = filter.rawValue
        // Локализация названий фильтров
        switch filter {
        case .tasksByDate:
            filterText = "Задачи на дату"
        case .completed:
            filterText = "Выполнена"
        case .created:
            filterText = "Создана"
        case .inProgress:
            filterText = "В процессе"
        case .testing:
            filterText = "Тестируется"
        case .readyForRelease:
            filterText = "Готово к релизу"
        case .overdue:
            filterText = "Просроченные"
        case .completedTrackers:
            filterText = "Завершённые"
        case .pinned:
            filterText = "Закреплённые"
        }
        cell.textLabel?.text = filterText
        cell.backgroundColor = .ypWhite
        cell.accessoryType = filter == selectedFilter ? .checkmark : .none
        return cell
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
}

// MARK: - UITableViewDelegate

extension FilterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let previousSelectedCell = tableView.cellForRow(at: indexPath)
        previousSelectedCell?.accessoryType = .none
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        tableView.deselectRow(at: indexPath, animated: true)
        let filter = filterSections[indexPath.section][indexPath.row]
        delegate?.filterSelected(filter: filter)
        analyticsService.report(event: .click, params: ["Screen" : "\(filter)"])
        dismiss(animated: true)
    }
}

