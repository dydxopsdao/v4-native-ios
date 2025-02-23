//
//  dydxNotificationsSettingsViewBuilder.swift
//  dydxPresenters
//
//  Created by Michael Maguire on 3/28/24.
//

import Utilities
import dydxViews
import PlatformParticles
import RoutingKit
import ParticlesKit
import PlatformUI
import PlatformUIJedio
import SwiftUI
import dydxStateManager
import JedioKit

public class dydxNotificationsSettingsViewBuilder: NSObject, ObjectBuilderProtocol {
    public func build<T>() -> T? {
        let presenter = dydxNotificationsSettingsViewPresenter()
        let view = presenter.viewModel?.createView() ?? PlatformViewModel().createView()
        let viewController = SettingsViewController(presenter: presenter, view: view, configuration: .default)
        viewController.requestPath = "/settings/notifications"
        return viewController as? T
    }
}

private class dydxNotificationsSettingsViewPresenter: SettingsViewPresenter {
    init() {
        super.init(definitionFile: "notifications.json",
                   keyValueStore: SettingsStore.shared,
                   appScheme: Bundle.main.scheme)

        let header = SettingHeaderViewModel()
        header.text = DataLocalizer.shared?.localize(path: "APP.V4.NOTIFICATIONS", params: nil)
        header.dismissAction = {
            Router.shared?.navigate(to: RoutingRequest(path: "/action/dismiss"), animated: true, completion: nil)
        }
        viewModel?.headerViewModel = header
    }

    override func start() {
        super.start()

        changeObservation(from: nil, to: NotificationService.shared, keyPath: #keyPath(NotificationHandler.permission)) { [weak self] _, _, _, _ in
            self?.reloadSettings()
        }
    }

    override func onInputValueChanged(input: FieldInput) {
        if input.fieldName == "should_display_in_app_notifications" {
           promptToToggleNotification()
        }
    }

    private func promptToToggleNotification() {
        let notificationPermission = NotificationService.shared?.authorization
        if notificationPermission?.authorization == .notDetermined {
            Router.shared?.navigate(to: RoutingRequest(path: "/authorization/notification", params: nil), animated: true, completion: nil)
        } else {
            notificationPermission?.promptToSettings(requestTitle: nil,
                                                     requestMessage: DataLocalizer.shared?.localize(path: "APP.PUSH_NOTIFICATIONS.UPDATE_SETTINGS_MESSAGE", params: nil),
                                                     requestCTA: DataLocalizer.shared?.localize(path: "APP.EMAIL_NOTIFICATIONS.SETTINGS", params: nil) ?? "Settings",
                                                     cancelTitle: DataLocalizer.shared?.localize(path: "APP.GENERAL.CANCEL", params: nil) ?? "Cancel"
            )
        }
        reloadSettings()
    }

    private func reloadSettings() {
        let pushNotificationEnabled = NotificationService.shared?.permission == .authorized
        SettingsStore.shared?.setValue(pushNotificationEnabled, forKey: dydxSettingsStoreKey.shouldDisplayInAppNotifications.rawValue)
        loadSettings()
    }
}
