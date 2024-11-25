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
    @State var currentNumber: String = "1"
    
    var body: some Scene {

        
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
