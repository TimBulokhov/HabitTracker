import UIKit
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import FirebaseFirestore

class AuthViewController: UIViewController {
    // MARK: - UI
    private let logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "AppLogo"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Добро пожаловать!"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.placeholder = "Email"
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .none
        field.keyboardType = .emailAddress
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.placeholder = "Пароль"
        field.borderStyle = .roundedRect
        field.isSecureTextEntry = true
        field.translatesAutoresizingMaskIntoConstraints = false
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "eye"), for: .normal)
        button.setImage(UIImage(systemName: "eye.slash"), for: .selected)
        button.tintColor = .gray
        field.rightView = button
        field.rightViewMode = .always
        return field
    }()
    
    private let confirmPasswordField: UITextField = {
        let field = UITextField()
        field.placeholder = "Повторите пароль"
        field.borderStyle = .roundedRect
        field.isSecureTextEntry = true
        field.translatesAutoresizingMaskIntoConstraints = false
        field.isHidden = true
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "eye"), for: .normal)
        button.setImage(UIImage(systemName: "eye.slash"), for: .selected)
        button.tintColor = .gray
        field.rightView = button
        field.rightViewMode = .always
        return field
    }()
    
    private let passwordStrengthView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.isHidden = true
        return progress
    }()
    
    private let passwordStrengthLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.isHidden = true
        return label
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Войти", for: .normal)
        button.backgroundColor = .ypBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let switchModeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Зарегистрироваться", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let googleButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Войти через Google", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 19, weight: .semibold)
        btn.backgroundColor = .white
        btn.setTitleColor(.black, for: .normal)
        btn.layer.cornerRadius = 14
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.systemGray4.cgColor
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let forgotPasswordButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Забыли пароль?", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        btn.setTitleColor(.systemGray, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let restorePasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Восстановить пароль", for: .normal)
        button.backgroundColor = .ypBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    private var isRegistrationMode = false
    private var isRestoreMode = false
    var isPasswordChangeMode = false
    
    private var customBackButton: UIButton?
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        view.backgroundColor = .ypWhite
        
        if isPasswordChangeMode {
            title = "Изменение пароля"
            passwordField.placeholder = "Новый пароль"
            confirmPasswordField.placeholder = "Повторите новый пароль"
            actionButton.setTitle("Изменить пароль", for: .normal)
            switchModeButton.isHidden = true
            googleButton.isHidden = true
            forgotPasswordButton.isHidden = true
            confirmPasswordField.isHidden = false
        }
        
        // Добавляем распознаватель тапа для скрытия клавиатуры
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        // Кастомная кнопка 'Назад' для режима восстановления пароля
        if isRestoreMode {
            showCustomBackButton()
        } else {
            hideCustomBackButton()
        }
        
        // Добавляем таргеты для глазиков
        if let button = passwordField.rightView as? UIButton {
            button.addTarget(self, action: #selector(togglePasswordVisibility(_:)), for: .touchUpInside)
        }
        if let button = confirmPasswordField.rightView as? UIButton {
            button.addTarget(self, action: #selector(toggleConfirmPasswordVisibility(_:)), for: .touchUpInside)
        }
    }
    
    private func setupUI() {
        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(emailField)
        view.addSubview(passwordField)
        view.addSubview(confirmPasswordField)
        view.addSubview(passwordStrengthView)
        view.addSubview(passwordStrengthLabel)
        view.addSubview(actionButton)
        view.addSubview(switchModeButton)
        view.addSubview(googleButton)
        view.addSubview(forgotPasswordButton)
        view.addSubview(restorePasswordButton)
        
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.heightAnchor.constraint(equalToConstant: 80),
            logoImageView.widthAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            emailField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emailField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            emailField.widthAnchor.constraint(equalToConstant: 300),
            
            passwordField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 20),
            passwordField.widthAnchor.constraint(equalToConstant: 300),
            
            confirmPasswordField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            confirmPasswordField.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 20),
            confirmPasswordField.widthAnchor.constraint(equalToConstant: 300),
            
            passwordStrengthView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordStrengthView.topAnchor.constraint(equalTo: confirmPasswordField.bottomAnchor, constant: 10),
            passwordStrengthView.widthAnchor.constraint(equalToConstant: 300),
            
            passwordStrengthLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordStrengthLabel.topAnchor.constraint(equalTo: passwordStrengthView.bottomAnchor, constant: 4),
            
            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actionButton.topAnchor.constraint(equalTo: passwordStrengthLabel.bottomAnchor, constant: 20),
            actionButton.widthAnchor.constraint(equalToConstant: 300),
            actionButton.heightAnchor.constraint(equalToConstant: 50),
            
            switchModeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            switchModeButton.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 20),
            
            googleButton.topAnchor.constraint(equalTo: switchModeButton.bottomAnchor, constant: 20),
            googleButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            googleButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            googleButton.heightAnchor.constraint(equalToConstant: 50),
            
            forgotPasswordButton.topAnchor.constraint(equalTo: googleButton.bottomAnchor, constant: 16),
            forgotPasswordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            restorePasswordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            restorePasswordButton.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 20),
            restorePasswordButton.widthAnchor.constraint(equalToConstant: 300),
            restorePasswordButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    private func setupConstraints() {
        // No additional constraints needed for the current setup
    }
    
    private func setupActions() {
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        switchModeButton.addTarget(self, action: #selector(switchModeTapped), for: .touchUpInside)
        passwordField.addTarget(self, action: #selector(passwordChanged), for: .editingChanged)
        googleButton.addTarget(self, action: #selector(googleTapped), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
        restorePasswordButton.addTarget(self, action: #selector(restorePasswordTapped), for: .touchUpInside)
        
        // Устанавливаем делегаты для текстовых полей
        emailField.delegate = self
        passwordField.delegate = self
        confirmPasswordField.delegate = self
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
    
    private func navigateToTracker() {
        let dataStorage = DataStorege.shared
        let rootVC = dataStorage.firstLaunchApplication ? TabBarController() : OnboardViewController()
        setRootViewController(rootVC)
    }
    
    // MARK: - Actions
    @objc private func actionButtonTapped() {
        guard let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            showAlert(title: "Ошибка", message: "Заполните все поля")
            return
        }
        
        if isRegistrationMode {
            guard let confirmPassword = confirmPasswordField.text,
                  confirmPassword == password else {
                showAlert(title: "Ошибка", message: "Пароли не совпадают")
                return
            }
            if password.count < 6 {
                showAlert(title: "Ошибка", message: "Пароль должен быть не менее 6 символов")
                return
            }
            // Регистрация
            Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
                if let error = error {
                    self?.showAlert(title: "Ошибка", message: error.localizedDescription)
                    return
                }
                // Создаем документ пользователя в Firestore
                if let userId = result?.user.uid {
                    let db = Firestore.firestore()
                    db.collection("users").document(userId).setData([
                        "email": email,
                        "createdAt": FieldValue.serverTimestamp()
                    ]) { error in
                        if let error = error {
                            print("Error creating user document: \(error)")
                        }
                    }
                }
                self?.showAlert(title: "Успех", message: "Регистрация успешно завершена") { [weak self] in
                    self?.navigateToTracker()
                }
            }
        } else {
            // Вход
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
                if let error = error {
                    self?.showAlert(title: "Ошибка", message: error.localizedDescription)
                    return
                }
                self?.navigateToTracker()
            }
        }
    }
    
    @objc private func switchModeTapped() {
        if isRestoreMode {
            resetToLoginMode()
            return
        }
        
        isRegistrationMode.toggle()
        
        if isRegistrationMode {
            actionButton.setTitle("Зарегистрироваться", for: .normal)
            switchModeButton.setTitle("Войти", for: .normal)
            confirmPasswordField.isHidden = false
        } else {
            actionButton.setTitle("Войти", for: .normal)
            switchModeButton.setTitle("Зарегистрироваться", for: .normal)
            confirmPasswordField.isHidden = true
            passwordStrengthView.isHidden = true
            passwordStrengthLabel.isHidden = true
        }
    }
    
    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        sender.isSelected.toggle()
        passwordField.isSecureTextEntry = !sender.isSelected
    }
    
    @objc private func toggleConfirmPasswordVisibility(_ sender: UIButton) {
        sender.isSelected.toggle()
        confirmPasswordField.isSecureTextEntry = !sender.isSelected
    }
    
    @objc private func passwordChanged() {
        guard isRegistrationMode else { return }
        let password = passwordField.text ?? ""
        
        if password.count < 6 {
            passwordStrengthView.isHidden = true
            passwordStrengthLabel.isHidden = true
            return
        }
        
        passwordStrengthView.isHidden = false
        passwordStrengthLabel.isHidden = false
        
        let strength = calculatePasswordStrength(password)
        passwordStrengthView.progress = Float(strength) / 100.0
        
        switch strength {
        case 0...30:
            passwordStrengthView.progressTintColor = .red
            passwordStrengthLabel.text = "Слабый"
            passwordStrengthLabel.textColor = .red
        case 31...70:
            passwordStrengthView.progressTintColor = .orange
            passwordStrengthLabel.text = "Средний"
            passwordStrengthLabel.textColor = .orange
        default:
            passwordStrengthView.progressTintColor = UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
            passwordStrengthLabel.text = "Надежный"
            passwordStrengthLabel.textColor = UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
        }
    }
    
    private func calculatePasswordStrength(_ password: String) -> Int {
        var strength = 0
        
        // Длина пароля (максимум 30 баллов)
        if password.count >= 8 { strength += 15 }
        if password.count >= 12 { strength += 15 }
        
        // Наличие цифр (20 баллов)
        if password.range(of: "\\d", options: .regularExpression) != nil { strength += 20 }
        
        // Наличие заглавных букв (20 баллов)
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { strength += 20 }
        
        // Наличие строчных букв (10 баллов)
        if password.range(of: "[a-z]", options: .regularExpression) != nil { strength += 10 }
        
        // Наличие специальных символов (20 баллов)
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { strength += 20 }
        
        return min(strength, 100)
    }
    
    @objc private func googleTapped() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] result, error in
            if let error = error {
                self?.showAlert(title: "Ошибка Google", message: error.localizedDescription)
                return
            }
            
            guard let user = result?.user else {
                self?.showAlert(title: "Ошибка Google", message: "Не удалось получить данные пользователя.")
                return
            }
            
            // Получаем токены
            let idToken = user.idToken?.tokenString ?? ""
            let accessToken = user.accessToken.tokenString
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self?.showAlert(title: "Ошибка Firebase", message: error.localizedDescription)
                } else if let user = authResult?.user {
                    // Сохраняем профиль в Firestore
                    let db = Firestore.firestore()
                    db.collection("users").document(user.uid).setData([
                        "email": user.email ?? "",
                        "createdAt": FieldValue.serverTimestamp()
                    ], merge: true)
                    self?.navigateToTracker()
                }
            }
        }
    }
    
    @objc private func forgotPasswordTapped() {
        isRestoreMode = true
        passwordField.isHidden = true
        confirmPasswordField.isHidden = true
        passwordStrengthView.isHidden = true
        passwordStrengthLabel.isHidden = true
        actionButton.isHidden = true
        switchModeButton.isHidden = true
        googleButton.isHidden = true
        forgotPasswordButton.isHidden = true
        restorePasswordButton.isHidden = false
        showCustomBackButton()
        // Очищаем поля
        passwordField.text = ""
        confirmPasswordField.text = ""
    }
    
    @objc private func restorePasswordTapped() {
        guard let email = emailField.text, !email.isEmpty else {
            showAlert(title: "Ошибка", message: "Введите email")
            return
        }
        
        // Отправляем письмо для сброса пароля
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            if let error = error {
                if error.localizedDescription.contains("no user record") {
                    self?.showAlert(title: "Ошибка", message: "Пользователь не существует. Проверьте email")
                } else {
                    self?.showAlert(title: "Ошибка", message: error.localizedDescription)
                }
                return
            }
            
            self?.showAlert(title: "Успех", message: "Письмо для сброса пароля отправлено на ваш email") { [weak self] in
                self?.resetToLoginMode()
            }
        }
    }
    
    @objc private func backButtonTapped() {
        resetToLoginMode()
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    private func resetToLoginMode() {
        isRestoreMode = false
        passwordField.isHidden = false
        confirmPasswordField.isHidden = true
        passwordStrengthView.isHidden = true
        passwordStrengthLabel.isHidden = true
        actionButton.isHidden = false
        switchModeButton.isHidden = false
        googleButton.isHidden = false
        forgotPasswordButton.isHidden = false
        restorePasswordButton.isHidden = true
        hideCustomBackButton()
        // Очищаем поля
        emailField.text = ""
        passwordField.text = ""
        confirmPasswordField.text = ""
    }
    
    @objc private func changePasswordTapped() {
        guard let newPassword = passwordField.text, !newPassword.isEmpty,
              let confirmPassword = confirmPasswordField.text, !confirmPassword.isEmpty else {
            showAlert(title: "Ошибка", message: "Заполните все поля")
            return
        }
        guard newPassword == confirmPassword else {
            showAlert(title: "Ошибка", message: "Пароли не совпадают")
            return
        }
        guard newPassword.count >= 6 else {
            showAlert(title: "Ошибка", message: "Пароль должен быть не менее 6 символов")
            return
        }
        Auth.auth().currentUser?.updatePassword(to: newPassword) { [weak self] error in
            if let error = error {
                self?.showAlert(title: "Ошибка", message: error.localizedDescription)
                return
            }
            self?.showAlert(title: "Успех", message: "Пароль успешно изменен") { [weak self] in
                self?.dismiss(animated: true)
            }
        }
    }
    
    private func showCustomBackButton() {
        if customBackButton == nil {
            let backButton = UIButton(type: .system)
            backButton.setTitle("Назад", for: .normal)
            backButton.setTitleColor(.ypBlack, for: .normal)
            backButton.titleLabel?.font = .systemFont(ofSize: 17)
            backButton.contentHorizontalAlignment = .left
            // Добавляем иконку
            let image = UIImage(systemName: "chevron.left")
            backButton.setImage(image, for: .normal)
            backButton.tintColor = .ypBlack
            backButton.semanticContentAttribute = .forceLeftToRight
            backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
            backButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(backButton)
            NSLayoutConstraint.activate([
                backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
                backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                backButton.widthAnchor.constraint(equalToConstant: 100),
                backButton.heightAnchor.constraint(equalToConstant: 40)
            ])
            customBackButton = backButton
        }
        customBackButton?.isHidden = false
    }
    
    private func hideCustomBackButton() {
        customBackButton?.isHidden = true
    }
}

// MARK: - Padding for UITextField
private extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}

// Добавляем делегаты для текстовых полей
extension AuthViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailField:
            passwordField.becomeFirstResponder()
        case passwordField:
            if isRegistrationMode {
                confirmPasswordField.becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
        case confirmPasswordField:
            textField.resignFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
} 
