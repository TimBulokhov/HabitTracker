import UIKit

final class NotificationsViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var notificationsByCategory: [String: [InternalNotification]] = [:]
    private var sortedCategories: [String] = []
    private var archiveNotifications: [InternalNotification] = []
    private let placeholderView = UIView()
    private let placeholderImage = UIImageView(image: UIImage(systemName: "bell.slash"))
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("no_notifications", comment: "no_notifications")
        label.textColor = .ypGray
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    private var existingCategoryTitles: [String] = []
    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.title = "Очистить все"
        config.baseForegroundColor = .ypBlue
        config.attributedTitle = AttributedString("Очистить все", attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .semibold)]))
        button.configuration = config
        button.addTarget(self, action: #selector(clearAllNotifications), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("notifications", comment: "notifications")
        view.backgroundColor = .ypWhite
        setupTableView()
        setupPlaceholder()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: clearButton)
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(NotificationCell.self, forCellReuseIdentifier: "NotificationCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .ypWhite
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupPlaceholder() {
        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        placeholderImage.tintColor = .ypGray
        placeholderImage.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderView.addSubview(placeholderImage)
        placeholderView.addSubview(placeholderLabel)
        view.addSubview(placeholderView)
        NSLayoutConstraint.activate([
            placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            placeholderImage.centerXAnchor.constraint(equalTo: placeholderView.centerXAnchor),
            placeholderImage.topAnchor.constraint(equalTo: placeholderView.topAnchor),
            placeholderImage.widthAnchor.constraint(equalToConstant: 60),
            placeholderImage.heightAnchor.constraint(equalToConstant: 60),
            placeholderLabel.topAnchor.constraint(equalTo: placeholderImage.bottomAnchor, constant: 12),
            placeholderLabel.leadingAnchor.constraint(equalTo: placeholderView.leadingAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: placeholderView.trailingAnchor),
            placeholderLabel.bottomAnchor.constraint(equalTo: placeholderView.bottomAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadNotifications()
    }
    
    @objc private func clearAllNotifications(_ sender: UIButton) {
        UIView.animate(withDuration: 0.08, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }, completion: { _ in
            UIView.animate(withDuration: 0.08) {
                sender.transform = .identity
            }
        })
        NotificationStore.shared.clearAll()
        reloadNotifications()
    }
    
    private func reloadNotifications() {
        let trackersCategoryStore = TrackersCategoryStorage()
        let coreDataCategories = (try? trackersCategoryStore.fetchAllCategories()) ?? []
        existingCategoryTitles = coreDataCategories.compactMap { $0.titleCategory?.trimmingCharacters(in: .whitespacesAndNewlines) }
        let allNotifications = NotificationStore.shared.notifications.sorted { $0.date > $1.date }
        let notificationCategories = Set(allNotifications.map { $0.category.trimmingCharacters(in: .whitespacesAndNewlines) })
        notificationsByCategory = [:]
        archiveNotifications = []
        for category in existingCategoryTitles {
            notificationsByCategory[category] = allNotifications.filter { $0.category.trimmingCharacters(in: .whitespacesAndNewlines) == category }
        }
        archiveNotifications = allNotifications.filter { notification in
            let normalizedCategory = notification.category.trimmingCharacters(in: .whitespacesAndNewlines)
            return !existingCategoryTitles.contains(normalizedCategory)
        }
        sortedCategories = existingCategoryTitles
        if !archiveNotifications.isEmpty {
            sortedCategories.append(NSLocalizedString("archive", comment: "archive"))
            notificationsByCategory[NSLocalizedString("archive", comment: "archive")] = archiveNotifications
        }
        tableView.reloadData()
        NotificationStore.shared.markAllAsRead()
        if let tabBar = self.tabBarController?.tabBar, let items = tabBar.items, items.count > 2 {
            items[2].badgeValue = nil
        }
        updatePlaceholder()
    }
    
    private func updatePlaceholder() {
        let isEmpty = sortedCategories.isEmpty
        placeholderView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
}

// MARK: - UITableViewDataSource

extension NotificationsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sortedCategories.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let category = sortedCategories[section]
        return notificationsByCategory[category]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortedCategories[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as! NotificationCell
        let category = sortedCategories[indexPath.section]
        if let notification = notificationsByCategory[category]?[indexPath.row] {
            cell.configure(with: notification)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension NotificationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = sortedCategories[indexPath.section]
        if let notification = notificationsByCategory[category]?[indexPath.row] {
            NotificationStore.shared.markAsRead(notification.id)
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - NotificationCell

final class NotificationCell: UITableViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .ypWhite
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.ypGray.withAlphaComponent(0.3).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let statusIndicator: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .ypBlack
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .ypBlack
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .ypGray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .ypGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let unreadIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .ypBlue
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(statusIndicator)
        containerView.addSubview(iconImageView)
        containerView.addSubview(unreadIndicator)
        containerView.addSubview(titleLabel)
        containerView.addSubview(bodyLabel)
        containerView.addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            statusIndicator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            statusIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            statusIndicator.widthAnchor.constraint(equalToConstant: 8),
            statusIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            iconImageView.leadingAnchor.constraint(equalTo: statusIndicator.trailingAnchor, constant: 8),
            iconImageView.centerYAnchor.constraint(equalTo: statusIndicator.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            unreadIndicator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            unreadIndicator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            unreadIndicator.widthAnchor.constraint(equalToConstant: 8),
            unreadIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            bodyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            timeLabel.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 8),
            timeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    private func getStatusColor(for notification: InternalNotification) -> UIColor {
        if notification.title.contains("тестируется") || notification.title.contains("перенесена") || notification.title.contains("перенесено") {
            // Orange: Тестируется/Перенос
            return UIColor(red: 247/255, green: 148/255, blue: 60/255, alpha: 1)
        } else if notification.title.contains("готово к релизу") || notification.title.contains("создана") || notification.title.contains("создано") {
            // Green: Готово к релизу/Создана
            return UIColor(red: 0/255, green: 165/255, blue: 80/255, alpha: 1)
        } else if notification.title.contains("завершена") || notification.title.contains("началось") {
            // Purple: Завершена/Началось
            return UIColor(red: 102/255, green: 0/255, blue: 153/255, alpha: 1)
        } else if notification.title.contains("просрочена") {
            return .ypRed
        } else if notification.title.contains("статус") {
            return .ypBlue
        } else {
            return .ypGray
        }
    }
    
    private func getIcon(for notification: InternalNotification) -> UIImage? {
        if notification.title.contains("просрочена") {
            return UIImage(systemName: "exclamationmark.circle.fill")
        } else if notification.title.contains("перенесена") || notification.title.contains("перенесено") {
            return UIImage(systemName: "arrow.right.circle.fill")
        } else if notification.title.contains("статус") {
            return UIImage(systemName: "checkmark.circle.fill")
        } else if notification.title.contains("создана") || notification.title.contains("создано") {
            return UIImage(systemName: "plus.circle.fill")
        } else if notification.title.contains("началось") {
            return UIImage(systemName: "play.circle.fill")
        } else {
            return UIImage(systemName: "bell.fill")
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "Сегодня в \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "Вчера в \(formatter.string(from: date))"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, HH:mm"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMMM, HH:mm"
            return formatter.string(from: date)
        }
    }
    
    private func getTitleColor(for notification: InternalNotification) -> UIColor {
        if notification.title.contains("создана") || notification.title.contains("создано") {
            return .ypBlack
        } else if notification.title.contains("тестируется") || notification.title.contains("перенесена") || notification.title.contains("перенесено") {
            return UIColor(red: 247/255, green: 148/255, blue: 60/255, alpha: 1)
        } else if notification.title.contains("готово к релизу") {
            return UIColor(red: 0/255, green: 165/255, blue: 80/255, alpha: 1)
        } else if notification.title.contains("завершена") || notification.title.contains("началось") {
            return UIColor(red: 102/255, green: 0/255, blue: 153/255, alpha: 1)
        } else if notification.title.contains("просрочена") {
            return .ypRed
        } else if notification.title.contains("статус") {
            return .ypBlue
        } else {
            return .ypGray
        }
    }
    
    func configure(with notification: InternalNotification) {
        titleLabel.text = notification.title
        bodyLabel.text = notification.body
        timeLabel.text = formatTime(notification.date)
        
        statusIndicator.backgroundColor = getStatusColor(for: notification)
        iconImageView.image = getIcon(for: notification)
        iconImageView.tintColor = getStatusColor(for: notification)
        unreadIndicator.isHidden = notification.isRead
        
        titleLabel.textColor = getTitleColor(for: notification)
        
        containerView.backgroundColor = notification.isRead ? .ypWhite : UIColor.ypGray.withAlphaComponent(0.1)
        
        if !notification.isRead {
            containerView.layer.shadowColor = UIColor.black.cgColor
            containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
            containerView.layer.shadowRadius = 4
            containerView.layer.shadowOpacity = 0.1
        } else {
            containerView.layer.shadowOpacity = 0
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        bodyLabel.text = nil
        timeLabel.text = nil
        iconImageView.image = nil
        unreadIndicator.isHidden = true
        statusIndicator.backgroundColor = .ypGray
        containerView.backgroundColor = .ypWhite
        containerView.layer.shadowOpacity = 0
    }
} 
