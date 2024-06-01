//
//  TrackersViewController.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit

// MARK: - TrackersViewController

final class TrackersViewController: UIViewController {
    private var filteredCategoriesBySearch: [TrackerCategory] = []
    private var filteredCategoriesByDate: [TrackerCategory] = []
    private var visibleCategories: [TrackerCategory] = []
    private var completedTrackers: [TrackerRecord] = []
    private var currentDate: Date = Date()
    private let trackersCategoryStore = TrackersCategoryStorage()
    private let trackersRecordStore = TrackersRecordStorage()
    private var categories: [TrackerCategory] = [] {
        didSet {
            visibleCategories = categories
        }
    }
    private let collectionSettings = CollectionSettings (
        cellCount: 2,
        topDistance: 9,
        leftDistance: 16,
        rightDistance: 16,
        cellSpacing: 9
    )
    
    // MARK: - UIElements
    
    private let navigationBar = UINavigationBar()
    
    private var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .ypWhiteDay
        collectionView.contentInset = UIEdgeInsets(top: .zero, left: .zero, bottom: .zero, right: .zero)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.backgroundColor = .ypBackgroundDay
        datePicker.preferredDatePickerStyle = .compact
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "ru_RU")
        datePicker.layer.cornerRadius = 8
        datePicker.calendar.firstWeekday = 2
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.addTarget(self, action: #selector(filterByDate), for: .valueChanged)
        return datePicker
    }()
    
    private lazy var trackerLabel: UILabel = {
        let trackerLabel = UILabel()
        trackerLabel.textColor = .ypBlackDay
        trackerLabel.text = "Trackers"
        trackerLabel.font = .boldSystemFont(ofSize: 34)
        trackerLabel.translatesAutoresizingMaskIntoConstraints = false
        return trackerLabel
    }()
    
    private lazy var searchBar: UISearchBar = {
        let trackersSearchBar = UISearchBar()
        trackersSearchBar.barTintColor = .ypGray
        trackersSearchBar.layer.masksToBounds = true
        trackersSearchBar.searchBarStyle = .minimal
        trackersSearchBar.translatesAutoresizingMaskIntoConstraints = false
        trackersSearchBar.placeholder = "Search"
        trackersSearchBar.delegate = self
        return trackersSearchBar
    }()
    
    private lazy var mainImageStub: UIImageView = {
        let mainImageStub = UIImageView()
        mainImageStub.clipsToBounds = true
        mainImageStub.contentMode = .scaleAspectFill
        mainImageStub.translatesAutoresizingMaskIntoConstraints = false
        return mainImageStub
    }()
    
    private lazy var searchMainPlaceholderStub: UILabel = {
        let searchSpacePlaceholderStack = UILabel()
        searchSpacePlaceholderStack.textColor = .ypBlackDay
        searchSpacePlaceholderStack.font = .systemFont(ofSize: 12, weight: .medium)
        searchSpacePlaceholderStack.translatesAutoresizingMaskIntoConstraints = false
        return searchSpacePlaceholderStack
    }()
    
    private lazy var placeholderView: UIView = {
        let view = UIView()
        view.endEditing(true)
        view.addSubview(mainImageStub)
        view.addSubview(searchMainPlaceholderStub)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainImageStub.widthAnchor.constraint(equalToConstant: 80),
            mainImageStub.heightAnchor.constraint(equalToConstant: 80),
            mainImageStub.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainImageStub.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            searchMainPlaceholderStub.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchMainPlaceholderStub.topAnchor.constraint(equalTo: mainImageStub.bottomAnchor, constant: 8)
        ])
        return view
    }()
    
    private lazy var addNewTrackerButton: UIButton = {
        let button = UIButton.systemButton(
            with: UIImage(named: "addTracker")!,
            target: self,
            action: #selector(self.addNewTracker))
        button.accessibilityIdentifier = "addNewTrackerButton"
        button.tintColor = .ypBlackDay
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configViews()
        configConstraints()
        configNavigationBar()
        configCollectionView()
        try? fetchACategory()
        checkingForActiveTrackers()
        updateVisibleCategories()
        try? fetchARecord()
    }
    
    // MARK: - Actions
    
    @objc
    private func addNewTracker() {
        let сreatingNewTrackerViewController = NewTrackerViewController()
        сreatingNewTrackerViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: сreatingNewTrackerViewController)
        present(navigationController, animated: true)
    }
    
    @objc
    private func filterByDate() {
        currentDate = datePicker.date
        updateVisibleCategories()
        dismiss(animated: true)
    }
    
    // MARK: - Private methods
    
    private func checkingForActiveTrackers() {
        if !visibleCategories.isEmpty {
            placeholderView.isHidden = true
            collectionView.isHidden = false
            collectionView.reloadData()
        } else {
            configPlaceholderStub()
        }
    }
    
    private func configPlaceholderStub() {
        placeholderView.isHidden = false
        collectionView.isHidden = true
        let searchText = searchBar.text ?? ""
        if visibleCategories.isEmpty && !categories.isEmpty || !searchText.isEmpty{
            searchMainPlaceholderStub.text = "Nothing found"
            mainImageStub.image = UIImage(named: "error2")
        } else {
            searchMainPlaceholderStub.text = "What you want to track?"
            mainImageStub.image = UIImage(named: "Error1")
        }
    }
    
    private func updateVisibleCategories() {
        let searchText = searchBar.text ?? ""
        if !searchText.isEmpty {
            filteredCategoriesBySearch = categories.map { category in
                let filteredTrackers = category.trackers.filter { $0.name.lowercased().contains(searchText.lowercased()) }
                return TrackerCategory(title: category.title, trackers: filteredTrackers)
            }.filter { !$0.trackers.isEmpty }
        } else {
            filteredCategoriesBySearch = categories
        }
        let dayOfWeek = currentDate.dayOfWeek()
        filteredCategoriesByDate = filteredCategoriesBySearch.map { categories in
            let filter = categories.trackers.filter {
                $0.dateEvents?.contains(dayOfWeek) ?? true
            }
            return TrackerCategory(title: categories.title, trackers: filter)
        } .filter { !$0.trackers.isEmpty}
        visibleCategories = filteredCategoriesByDate
        checkingForActiveTrackers()
        collectionView.reloadData()
    }
    
    private func сomparOfTrackerDates(date1: Date, date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.compare(date1, to: date2, toGranularity: .day) == .orderedSame
    }
    
    private func configNavigationBar() {
        let addTrackerBarButtonItem = UIBarButtonItem(customView: addNewTrackerButton)
        let datePickerBarButtonItem = UIBarButtonItem(customView: datePicker)
        let datePickerConstraint = NSLayoutConstraint(item: datePicker, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 110.0)
        navigationItem.leftBarButtonItem = addTrackerBarButtonItem
        navigationItem.rightBarButtonItems = [datePickerBarButtonItem]
        navigationBar.barTintColor = UIColor.ypWhiteDay
        navigationBar.shadowImage = UIImage()
        navigationBar.setItems([navigationItem], animated: false)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([datePickerConstraint])
    }
    
    private func configCollectionView() {
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: "TrackerCell")
        collectionView.register(SupplementaryView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderCategory")
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    private func configViews() {
        _ = self.skipKeyboard
        searchBar.setValue("Cancel", forKey: "cancelButtonText")
        view.backgroundColor = .ypWhiteDay
        view.addSubview(navigationBar)
        view.addSubview(trackerLabel)
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        view.addSubview(placeholderView)
    }
    
    private func configConstraints() {
        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            trackerLabel.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 1),
            trackerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.topAnchor.constraint(equalTo: trackerLabel.bottomAnchor, constant: 7),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            searchBar.heightAnchor.constraint(equalToConstant: 36),
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 34),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

// MARK: - UICollectionViewDataSource

extension TrackersViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleCategories[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrackerCell", for: indexPath) as? TrackerCell else { return UICollectionViewCell() }
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.row]
        let daysCount = completedTrackers.filter { $0.id == tracker.id }.count
        let IsCompleted = completedTrackers.contains {$0.id == tracker.id && сomparOfTrackerDates(date1: $0.date, date2: currentDate)}
        cell.delegate = self
        cell.setupCell(tracker: tracker)
        cell.completeTracker(days: daysCount, completed: IsCompleted)
        return cell
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return visibleCategories.count
    }
}

// MARK: - UICollectionViewDelegate

extension TrackersViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderCategory", for: indexPath) as? SupplementaryView else { return UICollectionReusableView()}
        view.titleLabel.text = visibleCategories[indexPath.section].title
        return view
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension TrackersViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let availableWidth = collectionView.bounds.width - collectionSettings.paddingWidth
        let cellWidth = availableWidth / CGFloat(collectionSettings.cellCount)
        return CGSize(width: cellWidth, height: cellWidth * 148/167)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(
            top: collectionSettings.topDistance,
            left: collectionSettings.leftDistance,
            bottom: collectionSettings.leftDistance,
            right: collectionSettings.rightDistance
        )
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return collectionSettings.cellSpacing
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        let indexPath = IndexPath(row: 0, section: section)
        let headerView = self.collectionView(
            collectionView,
            viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader,
            at: indexPath
        )
        return headerView.systemLayoutSizeFitting(CGSize(
            width: collectionView.frame.width,
            height: UIView.layoutFittingExpandedSize.height),
                                                  withHorizontalFittingPriority: .required,
                                                  verticalFittingPriority: .fittingSizeLevel)
    }
}

// MARK: - UISearchBarDelegate

extension TrackersViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            visibleCategories = categories
        } else {
            updateVisibleCategories()
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(true, animated: true)
        updateVisibleCategories()
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        visibleCategories = categories
        updateVisibleCategories()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        updateVisibleCategories()
    }
}

// MARK: - TrackerCreationDelegate

extension TrackersViewController: TrackerCreationDelegate {
    
    func didCreateTracker(_ tracker: Tracker, category: String) {
        try? createCategoryAndTracker(ctracker: tracker, with: category)
        try? fetchACategory()
        checkingForActiveTrackers()
        updateVisibleCategories()
        collectionView.reloadData()
    }
}

// MARK: - TrackerCellDelegate

extension TrackersViewController: TrackerCellDelegate {
    func trackerCompleted(id: UUID) {
        let record = TrackerRecord(id: id, date: currentDate)
        if currentDate <= Date() {
            if !completedTrackers.contains(where: { $0.id == id && Calendar.current.isDate($0.date, inSameDayAs: currentDate) }) {
                try? createARecord(record: record)
            }
            collectionView.reloadData()
        }
    }
    
    func trackerNotCompleted(id: UUID) {
        if let index = completedTrackers.firstIndex(where: { $0.id == id && Calendar.current.isDate($0.date, inSameDayAs: currentDate) }) {
            try? deleteARecord(atIndex: index)
        }
        try? fetchARecord()
        collectionView.reloadData()
    }
}
// MARK: - CategoryStore

extension TrackersViewController {
    private func fetchACategory() throws {
        do {
            let coreDataCategories = try trackersCategoryStore.fetchAllCategories()
            categories = try coreDataCategories.compactMap { coreDataCategory in
                return try trackersCategoryStore.decodingCategory(from: coreDataCategory)
            }
        } catch {
            throw StorageError.failedReading
        }
    }
    
    private func createCategoryAndTracker(ctracker: Tracker, with titleCategory: String) throws {
        do {
            try trackersCategoryStore.createCategoryAndTracker(tracker: ctracker, with: titleCategory)
        } catch {
            throw StorageError.failedToWrite
        }
    }
}

// MARK: - RecordStore

extension TrackersViewController {
    private func fetchARecord() throws {
        do {
            completedTrackers = try trackersRecordStore.fetchRecords()
            print(completedTrackers)
        } catch {
            throw StorageError.failedReading
        }
    }
    
    private func createARecord(record: TrackerRecord) throws {
        do {
            try trackersRecordStore.addNewRecord(from: record)
            try fetchARecord()
        } catch {
            throw StorageError.failedToWrite
        }
    }
    
    private func deleteARecord(atIndex index: Int) throws {
        let record = completedTrackers[index]
        print("record ---- \(record)")
        do {
            try trackersRecordStore.deleteATrackerRecord(trackerRecord: record)
            try fetchARecord()
        } catch {
            throw StorageError.failedActionDelete
        }
    }
}

// MARK: - TrackerStoreDelegate

extension TrackersViewController: TrackersCategoryStorageDelegate {
    func didUpdateData(in store: TrackersCategoryStorage) {
        collectionView.reloadData()
    }
}
