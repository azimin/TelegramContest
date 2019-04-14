//
//  AppDelegate.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()
        let viewController = ViewController(nibName: nil, bundle: nil)
        viewController.title = "Statistics"
        let navigationController = NavigationController(rootViewController: viewController)
        navigationController.theme = .default
        self.window?.makeKeyAndVisible()
        self.window?.rootViewController = navigationController
        return true
    }
}

class NavigationController: UINavigationController {
    var theme: Theme = .default {
        didSet {
            if theme.configuration.isLight != oldValue.configuration.isLight {
                self.animateThemeSwitch()
            }
            UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).backgroundColor = theme.configuration.mainBackgroundColor
//            UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).backgroundColor = UIColor.
            self.navigationBar.shadowImage = UIImage()
            self.navigationBar.isTranslucent = false
            self.navigationBar.barTintColor = theme.configuration.backgroundColor
            self.navigationBar.tintColor = theme.configuration.zoomOutText
            self.navigationBar.titleTextAttributes =
                [
                    NSAttributedString.Key.foregroundColor: theme.configuration.nameColor
            ]
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.configuration.isLight ? .default : .lightContent
    }

    func animateThemeSwitch() {
        if let snapshotView = self.view.snapshotView(afterScreenUpdates: false) {
            self.view.addSubview(snapshotView)
            UIView.animate(withDuration: 0.25, animations: {
                snapshotView.alpha = 0
            }) { (_) in
                snapshotView.removeFromSuperview()
            }
        }
    }
}
