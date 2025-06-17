import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

final class SettingsViewController: UIViewController {
    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    // Профиль
    private let profileHeader = UIView()
    private let profileTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Заполнение профиля"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private let avatarButton = UIButton(type: .system)
    private let avatarImageView = UIImageView()
    private let avatarOverlay = UIView()
    private let avatarEditIcon = UIImageView()
    private let emailLabel = UILabel()
    
    // Секции
    private let sectionsStack = UIStackView()
    
    // Личные данные
    private let personalDataSection = SettingsSection(title: "Личные данные")
    private let nameField: SettingsTextField = {
        let field = SettingsTextField()
        field.placeholder = "Имя"
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    private let surnameField: SettingsTextField = {
        let field = SettingsTextField()
        field.placeholder = "Фамилия"
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    private let tagField: SettingsTextField = {
        let field = SettingsTextField()
        field.placeholder = "Тег"
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    // Аккаунт
    private let accountSection = SettingsSection(title: "Аккаунт")
    private let changePasswordButton = SettingsButton(title: "Изменить пароль", icon: "key.fill", color: .systemBlue)
    private let logoutButton = SettingsButton(title: "Выйти", icon: "rectangle.portrait.and.arrow.right", color: .systemRed)
    
    // MARK: - Properties
    private var avatarImage: UIImage?
    private var avatarURL: String?
    private var userId: String? { Auth.auth().currentUser?.uid }
    private var userEmail: String? { Auth.auth().currentUser?.email }
    private var isFirstProfileSetup: Bool = false
    private var contentStackTopConstraint: NSLayoutConstraint?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        loadUserProfile()
    }
    
    func setupAsFirstProfile() {
        isFirstProfileSetup = true
        profileTitleLabel.isHidden = false
        profileTitleLabel.text = "Заполнение профиля"
        navigationItem.hidesBackButton = true
        view.layoutIfNeeded()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(named: "ypWhite")
        title = nil
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isScrollEnabled = true
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Content Stack
        contentStack.axis = .vertical
        contentStack.spacing = 32
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        let topOffset: CGFloat = isFirstProfileSetup ? 100 : 60
        contentStackTopConstraint = contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: topOffset)
        NSLayoutConstraint.activate([
            contentStackTopConstraint!,
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Profile Header
        profileHeader.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(profileHeader)
        
        // Profile Title Label
        profileHeader.addSubview(profileTitleLabel)
        NSLayoutConstraint.activate([
            profileTitleLabel.topAnchor.constraint(equalTo: profileHeader.topAnchor, constant: 20),
            profileTitleLabel.centerXAnchor.constraint(equalTo: profileHeader.centerXAnchor),
            profileTitleLabel.leadingAnchor.constraint(equalTo: profileHeader.leadingAnchor, constant: 20),
            profileTitleLabel.trailingAnchor.constraint(equalTo: profileHeader.trailingAnchor, constant: -20)
        ])
        
        // Avatar
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarButton.layer.cornerRadius = 40
        avatarButton.clipsToBounds = true
        avatarButton.backgroundColor = .systemGray6
        avatarButton.layer.borderWidth = 3
        avatarButton.layer.borderColor = UIColor.systemBlue.cgColor
        profileHeader.addSubview(avatarButton)
        
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarButton.addSubview(avatarImageView)
        
        avatarOverlay.translatesAutoresizingMaskIntoConstraints = false
        avatarOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        avatarOverlay.isHidden = true
        avatarButton.addSubview(avatarOverlay)
        
        avatarEditIcon.translatesAutoresizingMaskIntoConstraints = false
        avatarEditIcon.image = UIImage(systemName: "camera.fill")
        avatarEditIcon.tintColor = .white
        avatarEditIcon.contentMode = .scaleAspectFit
        avatarOverlay.addSubview(avatarEditIcon)
        
        NSLayoutConstraint.activate([
            avatarButton.centerXAnchor.constraint(equalTo: profileHeader.centerXAnchor),
            avatarButton.topAnchor.constraint(equalTo: profileTitleLabel.bottomAnchor, constant: 20),
            avatarButton.widthAnchor.constraint(equalToConstant: 80),
            avatarButton.heightAnchor.constraint(equalToConstant: 80),
            
            avatarImageView.topAnchor.constraint(equalTo: avatarButton.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarButton.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarButton.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarButton.bottomAnchor),
            
            avatarOverlay.topAnchor.constraint(equalTo: avatarButton.topAnchor),
            avatarOverlay.leadingAnchor.constraint(equalTo: avatarButton.leadingAnchor),
            avatarOverlay.trailingAnchor.constraint(equalTo: avatarButton.trailingAnchor),
            avatarOverlay.bottomAnchor.constraint(equalTo: avatarButton.bottomAnchor),
            
            avatarEditIcon.centerXAnchor.constraint(equalTo: avatarOverlay.centerXAnchor),
            avatarEditIcon.centerYAnchor.constraint(equalTo: avatarOverlay.centerYAnchor),
            avatarEditIcon.widthAnchor.constraint(equalToConstant: 24),
            avatarEditIcon.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Email
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.textColor = .secondaryLabel
        emailLabel.font = .systemFont(ofSize: 15)
        emailLabel.textAlignment = .center
        profileHeader.addSubview(emailLabel)
        
        NSLayoutConstraint.activate([
            emailLabel.topAnchor.constraint(equalTo: avatarButton.bottomAnchor, constant: 12),
            emailLabel.centerXAnchor.constraint(equalTo: profileHeader.centerXAnchor),
            emailLabel.leadingAnchor.constraint(equalTo: profileHeader.leadingAnchor, constant: 20),
            emailLabel.trailingAnchor.constraint(equalTo: profileHeader.trailingAnchor, constant: -20),
            emailLabel.bottomAnchor.constraint(equalTo: profileHeader.bottomAnchor, constant: -20)
        ])
        
        // Sections Stack
        sectionsStack.axis = .vertical
        sectionsStack.spacing = 24
        sectionsStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(sectionsStack)
        
        // Personal Data Section
        sectionsStack.addArrangedSubview(personalDataSection)
        personalDataSection.addArrangedSubview(nameField)
        personalDataSection.addArrangedSubview(surnameField)
        personalDataSection.addArrangedSubview(tagField)
        
        // Save Button
        let saveButton = SettingsButton(title: "Сохранить изменения", icon: "checkmark.circle.fill", color: .systemBlue)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        personalDataSection.addArrangedSubview(saveButton)
        
        let saveButtonBottomSpacer = UIView()
        saveButtonBottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        saveButtonBottomSpacer.heightAnchor.constraint(equalToConstant: 32).isActive = true
        personalDataSection.addArrangedSubview(saveButtonBottomSpacer)
        
        // Account Section
        let buttonsStack = UIStackView(arrangedSubviews: [changePasswordButton, logoutButton])
        buttonsStack.axis = .vertical
        buttonsStack.spacing = 16
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        sectionsStack.addArrangedSubview(buttonsStack)
        
        contentStack.alignment = .fill
        
        saveButton.isEnabled = true
        
        profileTitleLabel.isHidden = !isFirstProfileSetup
    }
    
    private func setupActions() {
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))
        avatarButton.addTarget(self, action: #selector(avatarTapped), for: .touchUpInside)
        avatarButton.addTarget(self, action: #selector(avatarTouchDown), for: .touchDown)
        
        // Устанавливаем делегаты для текстовых полей
        nameField.delegate = self
        surnameField.delegate = self
        tagField.delegate = self
        
        changePasswordButton.addTarget(self, action: #selector(changePasswordTapped), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        
        // Добавляем обработку тапа по экрану
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func textFieldDidChange() {
        updateAvatarImage()
    }
    
    private func updateAvatarImage() {
        avatarOverlay.isHidden = true
        if let avatarImage = avatarImage {
            avatarImageView.image = avatarImage
        } else {
            let name = nameField.text ?? ""
            let surname = surnameField.text ?? ""
            
            if name.isEmpty && surname.isEmpty {
                // Если имя и фамилия пустые, показываем знак вопроса
                let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
                avatarImageView.image = UIImage(systemName: "person.crop.circle.fill", withConfiguration: config)
                avatarImageView.tintColor = .systemGray
            } else {
                // Иначе показываем инициалы
                avatarImageView.image = generateInitialsImage(name: name, surname: surname)
            }
        }
    }
    
    @objc private func avatarTouchDown() {
        avatarOverlay.isHidden = false
    }
    
    @objc private func avatarTouchUp() {
        avatarOverlay.isHidden = true
    }
    
    @objc private func avatarTapped() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if avatarImage != nil {
            alert.addAction(UIAlertAction(title: "Удалить фото", style: .destructive) { [weak self] _ in
                guard let self = self, let userId = self.userId else { return }
                self.avatarImage = nil
                self.updateAvatarImage()
                self.avatarOverlay.isHidden = true
                self.deleteAvatarFile(userId: userId)
                
                // Обновляем профиль в Firestore, удаляя avatarFileName
                var updateData: [String: Any] = [
                    "name": self.nameField.text ?? "",
                    "surname": self.surnameField.text ?? "",
                    "tag": self.tagField.text ?? ""
                ]
                updateData["avatarFileName"] = FieldValue.delete()
                self.updateUserProfile(userId: userId, updateData: updateData)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Выбрать фото", style: .default) { [weak self] _ in
            self?.showImagePicker()
        })
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel) { [weak self] _ in
            self?.avatarOverlay.isHidden = true
            self?.updateAvatarImage()
        })
        present(alert, animated: true)
    }
    
    private func showImagePicker() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func removeAvatar() {
        avatarImage = nil
        avatarImageView.image = nil
        setInitialsAvatar()
        
        guard let userId = userId else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData(["avatarURL": FieldValue.delete()]) { [weak self] error in
            if let error = error {
                self?.showBanner(message: error.localizedDescription, isError: true)
            }
        }
    }
    
    @objc private func saveTapped() {
        view.endEditing(true)
        guard let name = nameField.text, !name.isEmpty,
              let surname = surnameField.text, !surname.isEmpty,
              let tag = tagField.text, !tag.isEmpty else {
            showAlert(title: "Ошибка", message: "Пожалуйста, заполните все обязательные поля")
            return
        }
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Ошибка", message: "Пользователь не авторизован")
            return
        }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        // Проверяем уникальность тега
        db.collection("users").whereField("tag", isEqualTo: tag).getDocuments { [weak self] snapshot, error in
            if let error = error {
                self?.showAlert(title: "Ошибка", message: error.localizedDescription)
                return
            }
            if let documents = snapshot?.documents, !documents.isEmpty {
                let isTagTakenByOtherUser = documents.contains { doc in
                    doc.documentID != user.uid
                }
                if isTagTakenByOtherUser {
                    self?.showAlert(title: "Ошибка", message: "Этот тег уже занят другим пользователем")
                    return
                }
            }
            // Сохраняем аватарку, если выбрана
            var updateData: [String: Any] = [
                "name": name,
                "surname": surname,
                "tag": tag
            ]
            if let avatarImage = self?.avatarImage {
                self?.saveAvatar(image: avatarImage) { fileName in
                    if let fileName = fileName {
                        updateData["avatarFileName"] = fileName
                    }
                    userRef.setData(updateData, merge: true) { [weak self] error in
                        self?.handleProfileSaveResult(error: error)
                    }
                }
            } else {
                userRef.setData(updateData, merge: true) { [weak self] error in
                    self?.handleProfileSaveResult(error: error)
                }
            }
        }
    }
    
    private func handleProfileSaveResult(error: Error?) {
        if let error = error {
            self.showAlert(title: "Ошибка", message: error.localizedDescription)
        } else {
            self.showBanner(message: "Данные сохранены", isError: false)
            if self.isFirstProfileSetup == true {
                self.profileTitleLabel.isHidden = true
                self.view.layoutIfNeeded()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    self.navigateToTabBar(animated: true)
                    self.isFirstProfileSetup = false
                }
            }
        }
    }
    
    private func updateUserProfile(userId: String, updateData: [String: Any]) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData(updateData) { [weak self] error in
            if let error = error {
                print("Error updating profile: \(error)")
                DispatchQueue.main.async {
                    self?.showBanner(message: "Ошибка обновления профиля", isError: true)
                }
            }
        }
    }
    
    @objc private func changePasswordTapped() {
        let alert = UIAlertController(title: "Изменить пароль", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Текущий пароль"
            textField.isSecureTextEntry = true
        }
        alert.addTextField { textField in
            textField.placeholder = "Новый пароль"
            textField.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Изменить", style: .default) { [weak self] _ in
            guard let currentPassword = alert.textFields?[0].text,
                  let newPassword = alert.textFields?[1].text else { return }
            self?.changePassword(currentPassword: currentPassword, newPassword: newPassword)
        })
        present(alert, animated: true)
    }
    
    @objc private func logoutTapped() {
        do {
            try Auth.auth().signOut()
            setRootViewController(AuthViewController())
        } catch {
            showBanner(message: error.localizedDescription, isError: true)
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Helpers
    private func loadUserProfile() {
        guard let userId = userId else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            if let error = error {
                print("Error loading profile: \(error)")
                return
            }
            guard let document = document, document.exists else {
                print("No profile found")
                return
            }
            let data = document.data()
            DispatchQueue.main.async {
                self.nameField.text = data?["name"] as? String ?? ""
                self.surnameField.text = data?["surname"] as? String ?? ""
                self.tagField.text = data?["tag"] as? String ?? ""
                self.emailLabel.text = self.userEmail
                
                // Загружаем аватар из файловой системы
                if let avatarFileName = data?["avatarFileName"] as? String,
                   let avatarImage = self.loadAvatarFromFileSystem(fileName: avatarFileName) {
                    self.avatarImage = avatarImage
                    self.avatarImageView.image = avatarImage
                } else {
                    self.updateAvatarImage()
                }
            }
        }
    }
    
    private func setInitialsAvatar() {
        let name = nameField.text ?? ""
        let surname = surnameField.text ?? ""
        let initials = (name.isEmpty && surname.isEmpty) ? "?" : "\(name.prefix(1))\(surname.prefix(1))"
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        label.text = initials
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 32, weight: .medium)
        label.textColor = .systemGray
        
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0.0)
        label.layer.render(in: UIGraphicsGetCurrentContext()!)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        avatarImageView.image = img
        avatarImageView.backgroundColor = .systemGray6
    }
    
    private func saveAvatar(image: UIImage, completion: @escaping (String?) -> Void) {
        guard let userId = userId else { completion(nil); return }
        
        if let fileName = saveAvatarToFileSystem(image: image, userId: userId) {
            completion(fileName)
        } else {
            DispatchQueue.main.async {
                self.showBanner(message: "Ошибка сохранения аватара", isError: true)
            }
            completion(nil)
        }
    }
    
    private func saveAvatarToFileSystem(image: UIImage, userId: String) -> String? {
        guard let avatarsDirectory = getAvatarsDirectory() else { return nil }
        
        let fileName = "\(userId).jpg"
        let fileURL = avatarsDirectory.appendingPathComponent(fileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        do {
            try imageData.write(to: fileURL)
            return fileName
        } catch {
            print("Error saving avatar: \(error)")
            return nil
        }
    }
    
    private func loadAvatarFromFileSystem(fileName: String) -> UIImage? {
        guard let avatarsDirectory = getAvatarsDirectory() else { return nil }
        let fileURL = avatarsDirectory.appendingPathComponent(fileName)
        
        guard let imageData = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: imageData)
    }
    
    private func changePassword(currentPassword: String, newPassword: String) {
        guard let user = Auth.auth().currentUser,
              let email = user.email else { return }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        user.reauthenticate(with: credential) { [weak self] _, error in
            if let error = error {
                self?.showBanner(message: error.localizedDescription, isError: true)
                return
            }
            
            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    self?.showBanner(message: error.localizedDescription, isError: true)
                } else {
                    self?.showBanner(message: "Пароль изменен", isError: false)
                }
            }
        }
    }
    
    private func showBanner(message: String, isError: Bool) {
        let banner = UIView()
        banner.backgroundColor = isError ? UIColor.systemRed : UIColor.systemGreen
        banner.layer.cornerRadius = 12
        banner.layer.masksToBounds = true
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.alpha = 0
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        banner.addSubview(label)
        view.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            banner.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            banner.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            label.topAnchor.constraint(equalTo: banner.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: banner.bottomAnchor, constant: -12)
        ])
        UIView.animate(withDuration: 0.3, animations: {
            banner.alpha = 1
            banner.transform = .identity
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.5, options: [], animations: {
                banner.alpha = 0
                banner.transform = CGAffineTransform(translationX: 0, y: 100)
            }) { _ in
                banner.removeFromSuperview()
            }
        }
    }
    
    private func getAvatarsDirectory() -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let avatarsDirectory = documentsDirectory.appendingPathComponent("avatars")
        
        // Создаем директорию, если её нет
        if !FileManager.default.fileExists(atPath: avatarsDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: avatarsDirectory, withIntermediateDirectories: true)
            } catch {
                print("Error creating avatars directory: \(error)")
                return nil
            }
        }
        
        return avatarsDirectory
    }
    
    private func generateInitialsImage(name: String, surname: String) -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Фон
            UIColor.systemGray5.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Получаем инициалы
            let firstInitial = name.prefix(1).uppercased()
            let secondInitial = surname.prefix(1).uppercased()
            let initials = "\(firstInitial)\(secondInitial)"
            
            // Настройки текста
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 40, weight: .medium),
                .foregroundColor: UIColor.systemGray
            ]
            
            // Размер текста
            let textSize = initials.size(withAttributes: attributes)
            
            // Позиция текста (по центру)
            let x = (size.width - textSize.width) / 2
            let y = (size.height - textSize.height) / 2
            
            // Рисуем текст
            initials.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
        }
    }
    
    private func deleteAvatarFile(userId: String) {
        guard let avatarsDirectory = getAvatarsDirectory() else { return }
        let fileURL = avatarsDirectory.appendingPathComponent("\(userId).jpg")
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("Avatar file deleted successfully")
        } catch {
            print("Error deleting avatar file: \(error)")
        }
    }
    
    private func setRootViewController(_ vc: UIViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        func dismissAllPresented(from root: UIViewController, completion: @escaping () -> Void) {
            if let presented = root.presentedViewController {
                presented.dismiss(animated: false) {
                    dismissAllPresented(from: root, completion: completion)
                }
            } else {
                completion()
            }
        }
        if let root = window.rootViewController {
            dismissAllPresented(from: root) {
                window.rootViewController = vc
                window.makeKeyAndVisible()
            }
        } else {
            window.rootViewController = vc
            window.makeKeyAndVisible()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func navigateToTabBar(animated: Bool = false) {
        let tabBarVC = TabBarController()
        if animated {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return }
            let transition = CATransition()
            transition.type = .fade
            transition.duration = 0.4
            window.layer.add(transition, forKey: kCATransition)
            window.rootViewController = tabBarVC
            window.makeKeyAndVisible()
        } else {
            setRootViewController(tabBarVC)
        }
    }
}

// MARK: - PHPickerViewControllerDelegate
extension SettingsViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        avatarOverlay.isHidden = true

        guard let result = results.first else {
            updateAvatarImage()
            return
        }

        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showBanner(message: error.localizedDescription, isError: true)
                    self?.avatarOverlay.isHidden = true
                }
                return
            }

            if let image = object as? UIImage {
                DispatchQueue.main.async {
                    self?.avatarImage = image
                    self?.avatarImageView.image = image
                    self?.avatarImageView.backgroundColor = .clear
                    self?.avatarOverlay.isHidden = true
                }
            }
        }
    }

    func pickerDidCancel(_ picker: PHPickerViewController) {
        avatarOverlay.isHidden = true
        updateAvatarImage()
    }
}

// MARK: - Settings Section
class SettingsSection: UIView {
    private let titleLabel = UILabel()
    private let contentStack = UIStackView()
    
    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        addSubview(contentStack)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 7),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -7),
            contentStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 7),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -7),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func addArrangedSubview(_ view: UIView) {
        contentStack.addArrangedSubview(view)
    }
    
    var alignment: UIStackView.Alignment {
        get { contentStack.alignment }
        set { contentStack.alignment = newValue }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Settings TextField
class SettingsTextField: UITextField {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTextField()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextField()
    }
    
    private func setupTextField() {
        backgroundColor = UIColor.secondarySystemBackground
        layer.cornerRadius = 12
        setLeftPaddingPoints(16)
        font = UIFont.systemFont(ofSize: 17)
        heightAnchor.constraint(equalToConstant: 60).isActive = true
    }
    
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}

// MARK: - UITextFieldDelegate
extension SettingsViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Запретить пробелы в поле тега
        if textField == tagField, string.contains(where: { $0.isWhitespace }) {
            return false
        }
        DispatchQueue.main.async { [weak self] in
            self?.updateAvatarImage()
        }
        return true
    }
}

// MARK: - Settings Button
class SettingsButton: UIButton {
    init(title: String, icon: String, color: UIColor) {
        super.init(frame: .zero)
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.title = title
            config.baseForegroundColor = color
            config.image = UIImage(systemName: icon)
            config.imagePadding = 8
            config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            config.attributedTitle = AttributedString(title, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .regular)]))
            self.configuration = config
        } else {
            setTitle(title, for: .normal)
            setTitleColor(color, for: .normal)
            setImage(UIImage(systemName: icon), for: .normal)
            tintColor = color
            backgroundColor = .clear
            titleLabel?.font = .systemFont(ofSize: 16)
            contentHorizontalAlignment = .center
        }
        heightAnchor.constraint(equalToConstant: 44).isActive = true
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
} 
