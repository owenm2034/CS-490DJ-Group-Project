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
//    let runner = AsyncProcessRunner()
    var body: some Scene {

        
        MenuBarExtra(currentNumber, systemImage: "\(currentNumber).circle") {
            // 3
//            let analyzer = Analyzer()
            Button("Start Capture") {
                self.currentNumber = "1"
//                appDelegate.startCapture()
//                runTcpdump()
//              runWhoAmI()
                tcpDumpWithPipe()
//                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
//                    runner.stopTask()
//                }
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
