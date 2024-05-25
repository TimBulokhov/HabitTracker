//
//  TrackerCategoryViewController.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit

// MARK: - CategoryViewDelegate

protocol TrackerCategoryViewControllerDelegate: AnyObject {
    func updateData(nameCategory: String)
}

// MARK: - CategoryViewController

final class TrackerCategoryViewController: UIViewController {
    weak var delegateHabbit: NewHabitViewControllerDelegate?
    weak var delegateIrregular: NewSingleHabitViewControllerDelegate?
    private let dataStorege = DataStorege.shared
    private var category = [String]()
    
    // MARK: - UiElements
    
    private var tableView: UITableView = .init()
    
    private lazy var habitLabel: UILabel = {
        let label = UILabel()
        label.text = "Category"
        label.textColor = .ypBlackDay
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var mainStarImageStub: UIImageView = {
        let image = UIImageView(image: UIImage(named: "Error1"))
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    private lazy var descriptionPlaceholderStub: UILabel = {
        let label = UILabel()
        label.text = "Habits and events can be\ncombined in meaning"
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var creatingHabitButton: UIButton = {
        let button = UIButton()
        button.setTitle("Add category", for: .normal)
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
        configConstraints()
        checkForAvailableCategories()
    }
    
    // MARK: - Actions
    
    @objc
    func actionsForButton() {
        let createCategoryViewController = CreatingCategoryViewController()
        createCategoryViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: createCategoryViewController)
        present(navigationController, animated: true)
    }
    
    // MARK: - Private methods
    
    private func checkForAvailableCategories() {
        category = dataStorege.loadCategories()
        tableView.reloadData()
        if !category.isEmpty {
            configTableView()
            configThereAreCategories()
        } else {
            configForCreateCategory()
        }
    }
    
    private func configTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CategoryCell")
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
        view.addSubview(habitLabel)
        view.addSubview(creatingHabitButton)
    }
    
    private func configConstraints() {
        NSLayoutConstraint.activate([
            habitLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            habitLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 27),
            creatingHabitButton.heightAnchor.constraint(equalToConstant: 60),
            creatingHabitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            creatingHabitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            creatingHabitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    private func configThereAreCategories() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: habitLabel.bottomAnchor, constant: 38),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: creatingHabitButton.topAnchor, constant: -38)
        ])
    }
    
    private func configForCreateCategory() {
        view.addSubview(mainStarImageStub)
        view.addSubview(descriptionPlaceholderStub)
        NSLayoutConstraint.activate([
            mainStarImageStub.widthAnchor.constraint(equalToConstant: 80),
            mainStarImageStub.heightAnchor.constraint(equalToConstant: 80),
            mainStarImageStub.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStarImageStub.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            descriptionPlaceholderStub.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descriptionPlaceholderStub.topAnchor.constraint(equalTo: mainStarImageStub.bottomAnchor, constant: 8)
        ])
    }
    
    private func roundingForCellsInATable(cellIndex: Int, numberOfLines: Int) -> CACornerMask {
        switch (cellIndex, numberOfLines) {
        case (0, 1):
            return [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        case (0, _):
            return [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        case (_, _) where cellIndex == numberOfLines - 1:
            return [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        default:
            return []
        }
    }
}

// MARK: - CategoryViewDelegate

extension TrackerCategoryViewController: TrackerCategoryViewControllerDelegate {
    func updateData(nameCategory: String) {
        dataStorege.saveCategories(nameCategory)
        category = dataStorege.loadCategories()
        checkForAvailableCategories()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate

extension TrackerCategoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let editingIndexPath = dataStorege.loadIndexPathForCheckmark() {
            let previousSelectedCell = tableView.cellForRow(at: editingIndexPath)
            previousSelectedCell?.accessoryType = .none
        }
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        dataStorege.saveIndexPathForCheckmark(indexPath)
        delegateIrregular?.updateSubitle(nameSubitle: category[indexPath.row])
        delegateHabbit?.updateSubitle(nameSubitle: category[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let deleteAction = UIAction(title: "Delete", attributes: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.dataStorege.removeCategory(atIndex: indexPath.row)
            self.checkForAvailableCategories()
        }
        let deleteMenu = UIMenu(title: "", children: [deleteAction])
        return UIContextMenuConfiguration(actionProvider: { _ in
            deleteMenu
        })
    }
}

// MARK: - UITableViewDataSource

extension TrackerCategoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return category.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        let categoryName = category[indexPath.row]
        cell.textLabel?.text = categoryName
        cell.backgroundColor = .ypBackgroundDay
        cell.layer.masksToBounds = true
        cell.layer.cornerRadius = 10
        cell.layer.maskedCorners = roundingForCellsInATable(cellIndex: indexPath.row, numberOfLines: category.count)
        cell.accessoryType = indexPath == dataStorege.loadIndexPathForCheckmark() ? .checkmark : .none
        return cell
    }
}
