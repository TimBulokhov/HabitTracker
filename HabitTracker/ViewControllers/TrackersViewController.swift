//
//  TrackersViewController.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit

protocol EditTrackerDelegate: AnyObject {
    func trackerUpdate(_ tracker: Tracker, category: String)
}

// MARK: - TrackersViewController

final class TrackersViewController: UIViewController {
    weak var delegateStatistic: StatisticViewControllerProtocol?
    private let trackerStore = TrackersStorage()
    private let analyticsService = AnalyticsService()
    private var selectedFilter: FilterName?
    private var pinnedCategory = NSLocalizedString("pinnedTrackers", comment: "pinnedTrackers")
    private var filteredCategoriesBySearch: [TrackerCategory] = []
    private var filteredCategoriesByDate: [TrackerCategory] = []
    private var visibleCategories: [TrackerCategory] = []
    private var completedTrackers: [TrackerRecord] = []
    private var selectedDate: Date = Date()
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
        collectionView.contentInset = UIEdgeInsets(top: .zero, left: .zero, bottom: 50, right: .zero)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.alwaysBounceVertical = true
        return collectionView
    }()
    
    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.backgroundColor = .ypBackgroundDay
        datePicker.preferredDatePickerStyle = .compact
        datePicker.datePickerMode = .date
        datePicker.locale = Locale.current
        datePicker.layer.cornerRadius = 8
        datePicker.calendar.firstWeekday = 2
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.addTarget(self, action: #selector(filterByDate), for: .valueChanged)
        return datePicker
    }()
    
    private lazy var trackerLabel: UILabel = {
        let trackerLabel = UILabel()
        trackerLabel.textColor = .ypBlackDay
        trackerLabel.text = NSLocalizedString("trackerTitle", comment: "trackerTitle")
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
        trackersSearchBar.placeholder = NSLocalizedString("search", comment: "search")
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
    
    private lazy var filterButton: UIButton = {
        let button = UIButton()
        let textTitle = NSLocalizedString("filterButton", comment: "filterButton")
        button.setTitle(textTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        button.setTitleColor(.ypWhiteDay, for: .normal)
        button.backgroundColor = .ypBlue
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(filterButtonAction), for: .touchUpInside)
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
        analyticsService.report(event: .open, params: ["Screen" : "Main"])
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        analyticsService.report(event: .close, params: ["Screen" : "Main"])
    }
    
    // MARK: - Actions
    
    @objc
    private func addNewTracker() {
        let сreatingNewTrackerViewController = NewTrackerViewController()
        сreatingNewTrackerViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: сreatingNewTrackerViewController)
        analyticsService.report(event: .click, params: ["Screen" : "Main", "Item" : Items.addTracker.rawValue])
        present(navigationController, animated: true)
    }
    
    @objc
    private func filterByDate() {
        selectedDate = datePicker.date
        updateVisibleCategories()
        dismiss(animated: true)
        analyticsService.report(event: .click, params: ["Screen" : "DatePicker", "Item" : Items.filterByDate.rawValue])
    }
    
    @objc
    private func filterButtonAction() {
        let filterViewController = FilterViewController()
        filterViewController.delegate = self
        filterViewController.selectedFilter = selectedFilter
        let navigationController = UINavigationController(rootViewController: filterViewController)
        present(navigationController, animated: true)
        analyticsService.report(event: .click, params: ["Screen" : "FilterView", "Item" : Items.filter.rawValue])
    }
    
    // MARK: - Private methods
    
    private func statisticsListener() {
        delegateStatistic?.completedTrackers = completedTrackers
    }
    
    private func checkingForActiveTrackers() {
        if visibleCategories.isEmpty {
            placeholderDisplaySwitch(isHidden: false)
            configPlaceholderStub()
        } else {
            placeholderDisplaySwitch(isHidden: true)
            collectionView.reloadData()
        }
    }
    
    private func placeholderDisplaySwitch(isHidden: Bool) {
        placeholderView.isHidden = isHidden
        collectionView.isHidden = !isHidden
        filterButton.isHidden = false
    }
    
    private func configPlaceholderStub() {
        let searchText = searchBar.text ?? ""
        if visibleCategories.isEmpty && !categories.isEmpty && !searchText.isEmpty {
            searchMainPlaceholderStub.text = NSLocalizedString("searchErrorStub", comment: "searchErrorStub")
            mainImageStub.image = UIImage(named: "error2")
        } else {
            searchMainPlaceholderStub.text = NSLocalizedString("emptyErrorStub", comment: "emptyErrorStub")
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
        let dayOfWeek = selectedDate.dayOfWeek()
        filteredCategoriesByDate = filteredCategoriesBySearch.map { categories in
            let filter = categories.trackers.filter {
                $0.dateEvents?.contains(dayOfWeek) ?? true
            }
            return TrackerCategory(title: categories.title, trackers: filter)
        } .filter { !$0.trackers.isEmpty}
        visibleCategories = filteredCategoriesByDate
        if selectedFilter == .completedTrackers {
            filteringTrackers(completed: true)
        } else if selectedFilter == .uncompletedTrackers {
            filteringTrackers(completed: false)
        }
        checkingForActiveTrackers()
        collectionView.reloadData()
    }
    
    private func filteringTrackers(completed: Bool) {
        visibleCategories = visibleCategories.compactMap { category in
            let trackers = category.trackers.filter { tracker in
                completed ? isTrackersRecordCompletedToday(id: tracker.id, date: selectedDate)
                : !isTrackersRecordCompletedToday(id: tracker.id, date: selectedDate)
            }
            if trackers.isEmpty { return nil }
            return TrackerCategory(title: category.title, trackers: trackers)
        }
    }
    
    private func isTrackersRecordCompletedToday(id: UUID, date: Date) -> Bool {
        completedTrackers.contains { record in
            let isSameDay = Calendar.current.isDate(record.date, inSameDayAs: date)
            return record.id == id && isSameDay
        }
    }
    
    private func сomparOfTrackerDates(date1: Date, date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.compare(date1, to: date2, toGranularity: .day) == .orderedSame
    }
    
    private func configNavigationBar() {
        let addTrackerBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewTracker))
        addTrackerBarButtonItem.tintColor = UIColor.ypBlackDay
        navigationItem.leftBarButtonItem = addTrackerBarButtonItem
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
        searchBar.setValue(NSLocalizedString("cancel", comment: "cancel"), forKey: "cancelButtonText")
        view.backgroundColor = .ypWhiteDay
        view.addSubview(navigationBar)
        view.addSubview(trackerLabel)
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        view.addSubview(placeholderView)
        view.addSubview(filterButton)
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
            placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            filterButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            filterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterButton.widthAnchor.constraint(equalToConstant: 114),
            filterButton.heightAnchor.constraint(equalToConstant: 50)
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
        let IsCompleted = completedTrackers.contains {$0.id == tracker.id && сomparOfTrackerDates(date1: $0.date, date2: selectedDate)}
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
    
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemsAt indexPaths: [IndexPath],
                        point: CGPoint) -> UIContextMenuConfiguration? {
        guard indexPaths.count > 0 else { return nil }
        let indexPath = indexPaths[0]
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.row]
        let titleTextisPinned = tracker.isPinned ? NSLocalizedString("unpinTracker", comment: "unpinTracker") : NSLocalizedString("pinTracker", comment: "pinTracker")
        
        let contextMenu = UIMenu(
            children: [
                UIAction(title: titleTextisPinned ) { [weak self] _ in
                    guard let self else { return }
                    self.updateStatusIsPinned(tracker: tracker)
                    self.analyticsService.report(event: .click, params: ["Screen" : "NewSingleHabit", "Item" : tracker.isPinned ? Items.pinned.rawValue : Items.unpinned.rawValue])
                },
                UIAction(title: NSLocalizedString("editTracker", comment: "editTracker")) { [weak self] _ in
                    guard let self else { return }
                    self.editingTrackers(indexPath: indexPath)
                    self.analyticsService.report(event: .click, params: ["Screen" : "NewSingleHabit", "Item" : Items.edit.rawValue])
                },
                UIAction(title: NSLocalizedString("deleteTracker", comment: "deleteTracker"), image: nil, identifier: nil, discoverabilityTitle: nil, attributes: .destructive) {[weak self] _ in
                    guard let self else { return }
                    self.showDeleteAlert(indexPath: indexPath)
                    self.analyticsService.report(event: .click, params: ["Screen" : "NewSingleHabit", "Item" : Items.delete.rawValue])
                }
            ])
        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            return contextMenu
        }
        return configuration
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfiguration configuration: UIContextMenuConfiguration,
                        highlightPreviewForItemAt indexPath: IndexPath) -> UITargetedPreview? {
        guard let cell = collectionView.cellForItem(at: indexPath) as? TrackerCell else { return nil }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        let view = cell.backgroundCellView
        return UITargetedPreview(view: view, parameters: parameters)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfiguration configuration: UIContextMenuConfiguration,
                        dismissalPreviewForItemAt indexPath: IndexPath) -> UITargetedPreview? {
        guard let cell = collectionView.cellForItem(at: indexPath) as? TrackerCell else { return nil }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        let view = cell.backgroundCellView
        return UITargetedPreview(view: view, parameters: parameters)
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
        let record = TrackerRecord(id: id, date: selectedDate)
        if selectedDate <= Date() {
            if !completedTrackers.contains(where: { $0.id == id && Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
                try? createARecord(record: record)
            }
            analyticsService.report(event: .click, params: ["Screen" : "Main", "Item" : Items.trackerCompleted.rawValue])
            collectionView.reloadData()
        }
    }

    func trackerNotCompleted(id: UUID) {
        if let index = completedTrackers.firstIndex(where: { $0.id == id && Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
            try? deleteARecord(atIndex: index)
        }
        try? fetchARecord()
        analyticsService.report(event: .click, params: ["Screen" : "Main", "Item" : Items.trackerNotCompleted.rawValue])
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
    
    private func deleteTrackerInCategory(atIndex index: IndexPath) throws {
        let tracker = visibleCategories[index.section].trackers[index.row]
        do {
            try trackerStore.deleteTrackers(tracker: tracker)
            try fetchACategory()
        } catch {
            throw StorageError.failedActionDelete
        }
    }
}

// MARK: - RecordStore

extension TrackersViewController {
    private func fetchARecord() throws {
        do {
            completedTrackers = try trackersRecordStore.fetchRecords()
            statisticsListener()
        } catch {
            throw StorageError.failedReading
        }
    }
    
    private func createARecord(record: TrackerRecord) throws {
        do {
            try trackersRecordStore.addNewRecord(from: record)
            try fetchARecord()
            statisticsListener()
        } catch {
            throw StorageError.failedToWrite
        }
    }
    
    private func deleteARecord(atIndex index: Int) throws {
        let record = completedTrackers[index]
        do {
            try trackersRecordStore.deleteATrackerRecord(trackerRecord: record)
            try fetchARecord()
            statisticsListener()
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

// MARK: - FilterViewControllerProtocol

extension TrackersViewController: FilterViewControllerProtocol {
    func filterSelected(filter: FilterName) {
        selectedFilter = filter
        searchBar.text = ""
        switch filter {
        case .allTrackers:
            filterButton.setTitleColor(.ypWhiteDay, for: .normal)
        case .todayTrackers:
            datePicker.setDate(Date(), animated: false)
            selectedDate = datePicker.date
            filterButton.setTitleColor(.ypWhiteDay, for: .normal)
        case .completedTrackers:
            filterButton.setTitleColor(.ypRed, for: .normal)
        case .uncompletedTrackers:
            filterButton.setTitleColor(.ypRed, for: .normal)
        }
        updateVisibleCategories()
    }
}

// MARK: - ConfigContextMenu

extension TrackersViewController {
    private func showDeleteAlert(indexPath: IndexPath) {
        let alert = UIAlertController(title: nil, message: NSLocalizedString("showDeleteAlert", comment: "showDeleteAlert"), preferredStyle: .actionSheet)
        let deleteButton = UIAlertAction(title: NSLocalizedString("deleteTracker", comment: "deleteTracker"), style: .destructive) { [weak self] _ in
            guard let self else { return }
            do {
                try self.deleteTrackerInCategory(atIndex: indexPath)
                self.updateVisibleCategories()
            } catch {
                print("Error deleting tracker: \(error)")
            }
        }
        let cancelButton = UIAlertAction(title: NSLocalizedString("cancel", comment: "cancel"), style: .cancel)
        alert.addAction(deleteButton)
        alert.addAction(cancelButton)
        self.present(alert, animated: true)
    }
}

// MARK: - pinnedTrackers

extension TrackersViewController {
    private func visiblePinnedCategory(){
        let allTrackersIsPinned = visibleCategories.flatMap { $0.trackers.filter { $0.isPinned } }
        categories = categories.map { category in
            var mutableCategory = category
            mutableCategory.trackers = category.trackers.filter { !$0.isPinned }
            return mutableCategory
        }
        let newCategory = TrackerCategory(title: pinnedCategory, trackers: allTrackersIsPinned)
        if let index = categories.firstIndex(where: { $0.title == newCategory.title }) {
            categories[index].trackers += newCategory.trackers
        } else {
            categories.insert(newCategory, at: 0)
        }
    }
    
    private func updateStatusIsPinned(tracker: Tracker){
        let updateTracker = Tracker(
            id: tracker.id,
            name: tracker.name,
            color: tracker.color,
            emoji: tracker.emoji,
            dateEvents: tracker.dateEvents,
            isPinned: tracker.isPinned ? false : true
        )
        try? trackerStore.updateTracker(with: updateTracker)
        try? fetchACategory()
        updateVisibleCategories()
    }
}

// MARK: - editingTrackers

extension TrackersViewController: EditTrackerDelegate {
    func trackerUpdate(_ tracker: Tracker, category: String) {
        try? trackerStore.updateTracker(with: tracker)
        try? fetchACategory()
        updateVisibleCategories()
    }
    
    private func editingTrackers(indexPath: IndexPath) {
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.row]
        let category = visibleCategories[indexPath.section].title
        let daysCount = completedTrackers.filter { $0.id == tracker.id }.count
        if tracker.dateEvents != nil {
            let createHabitViewController = NewHabitViewController()
            let navigationController = UINavigationController(rootViewController: createHabitViewController)
            createHabitViewController.delegateEdit = self
            createHabitViewController.numberOfDaysCompletedHabit = daysCount
            createHabitViewController.editCategoryHabit = category
            createHabitViewController.editTrackerHabit = tracker
            present(navigationController, animated: true)
        } else {
            let createIrregularEventViewController = NewSingleHabitViewController()
            let navigationController = UINavigationController(rootViewController: createIrregularEventViewController)
            createIrregularEventViewController.delegateEdit = self
            createIrregularEventViewController.numberOfDaysCompletedIrregular = daysCount
            createIrregularEventViewController.editCategoryIrregular = category
            createIrregularEventViewController.editTrackerIrregular = tracker
            present(navigationController, animated: true)
        }
    }
}

