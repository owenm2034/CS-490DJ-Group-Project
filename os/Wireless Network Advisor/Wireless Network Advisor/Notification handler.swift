//
//  Notification handler.swift
//  Wireless Network Advisor
//
//  Created by Owen Monus on 2024-11-28.
//

import Foundation
import UserNotifications


public func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if granted {
            print("Notification permission granted")
        } else if let error = error {
            print("Error: \(error.localizedDescription)")
        }
    }
}

func scheduleNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Reminder"
    content.body = "This is your scheduled notification!"
    content.sound = .default

    // Trigger after 5 seconds
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

    let request = UNNotificationRequest(identifier: "notification_id", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error: \(error.localizedDescription)")
        } else {
            print("Notification scheduled!")
        }
    }
}
