//
//  MenuBar.swift
//  Wireless Network Advisor
//
//  Created by Owen Monus on 2024-11-19.
//

import SwiftUI
import Cocoa

@main
struct MenuBarApp: App {
    // Create a reference to the app
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//    @Object private var analyzer = Analyzer();
    @State var currentNumber: String = "1"
    
    var body: some Scene {
//        WindowGroup {
////            ContentView()
//        }
        
        // 2
        MenuBarExtra(currentNumber, systemImage: "\(currentNumber).circle") {
            // 3
//            let analyzer = Analyzer()
            Button("Start Capture") {
                self.currentNumber = "1"
//                appDelegate.startCapture()
                runTcpdump()
            }
            Button("Stop") {
                self.currentNumber = "2"
//                appDelegate.quitApp()
            }
            Divider()
            
            Button("Quit") {
//                analyzer.stop()
                NSApplication.shared.terminate(nil)

            }.keyboardShortcut("q")
        }
    }
}

//// AppDelegate to handle the menu bar item and app lifecycle
//class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
//    var statusItem: NSStatusItem!
//
//    func setup() {
//        // Set up the status bar item
//        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
//
//        if let button = statusItem.button {
//            button.title = "🔍" // Set the menu bar icon
//        }
//
//        // Create a menu for the status item
//        let menu = NSMenu()
//
//        // Add menu items
//        let startCaptureItem = NSMenuItem(title: "Start Packet Capture", action: #selector(startCapture), keyEquivalent: "")
//        menu.addItem(startCaptureItem)
//
//        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
//        menu.addItem(quitItem)
//
//        // Attach the menu to the status item
//        statusItem.menu = menu
//    }
//
//    @objc func startCapture() {
//        // This is where you'd integrate your packet capture code
////        print("Starting packet capture...")
//        let dev = "en0"  // Wi-Fi interface on macOS (adjust as needed)
//            
//            // Convert Swift String to C String
//            let cString = dev.cString(using: .utf8)
//            
//            // Call the C function
//            if let cString = cString {
//                start_capture(cString)
//        }
//    }
//
//    @objc func quitApp() {
//        // Terminate the application
//        NSApplication.shared.terminate(self)
//    }
//}
