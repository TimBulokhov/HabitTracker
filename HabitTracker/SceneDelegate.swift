//
//  SceneDelegate.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit
import FirebaseCore
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    let dataStorage = DataStorege.shared
    var window: UIWindow?
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Инициализируем Firebase
        FirebaseApp.configure()
        
        let window = UIWindow(windowScene: windowScene)
        
        // Проверяем, авторизован ли пользователь
        if Auth.auth().currentUser != nil {
            // Если пользователь уже авторизован, показываем основной интерфейс
        window.rootViewController = dataStorage.firstLaunchApplication ? (TabBarController()) : (OnboardViewController())
        } else {
            // Если пользователь не авторизован, показываем экран авторизации
            window.rootViewController = AuthViewController()
        }
        
        window.makeKeyAndVisible()
        self.window = window
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}

