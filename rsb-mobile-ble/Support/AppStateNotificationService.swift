//
//  AppStateNotificationService.swift
//  rsb-mobile-ble
//
//  Created by Astro on 6/29/24.
//

import UIKit

enum AppState {
    case foreground
    case background
}

class AppStateNotificationService {
    @Published var appState = AppState.background
    let notificationCenter = NotificationCenter.default

    init() {
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func appMovedToBackground(_ notification: Notification) {
        appState = .background
    }

    @objc
    func appMovedToForeground(_ notification: Notification) {
        appState = .foreground
    }
}
