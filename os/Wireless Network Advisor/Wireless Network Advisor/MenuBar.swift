//
//  MenuBar.swift
//  Wireless Network Advisor
//
//  Created by Owen Monus on 2024-11-19.
//

import SwiftUI

@main
struct swiftui_menu_barApp: App {
    // 1
    @State var currentNumber: String = "1"
    
    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
        // 2
        MenuBarExtra(currentNumber, systemImage: "\(currentNumber).circle") {
            // 3
//            let analyzer = Analyzer()
            Button("Start") {
                currentNumber = "1"
//                analyzer.start()
            }
            Button("Stop") {
                currentNumber = "2"
//                analyzer.stop()
            }
//            Button("Three") {
//                currentNumber = "3"
//            }
            Divider()
            
            Button("Quit") {
//                analyzer.stop()
                NSApplication.shared.terminate(nil)

            }.keyboardShortcut("q")
        }
    }
}
