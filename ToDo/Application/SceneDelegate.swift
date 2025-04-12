//
//  SceneDelegate.swift
//  ToDo
//
//  Created by Ivan on 07.04.2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Create the window
        window = UIWindow(windowScene: windowScene)

        // --- Set up the initial View Controller ---
        // 1. Create the first screen (TaskListsViewController)
        let taskListsVC = TaskListsViewController()

        // 2. Embed it in a Navigation Controller to allow pushing other screens
        let navigationController = UINavigationController(rootViewController: taskListsVC)

        // 3. Set the Navigation Controller as the window's root view controller
        window?.rootViewController = navigationController

        // 4. Make the window visible
        window?.makeKeyAndVisible()
    }

    // Other SceneDelegate methods (leave as default)...
    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
