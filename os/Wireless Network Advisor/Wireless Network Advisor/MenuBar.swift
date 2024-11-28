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
    @State var insecurePacketCount: Int = 0
    @State var running = false
    @State var action = "Start Capture"
    //    let runner = AsyncProcessRunner()
    var body: some Scene {
        //        MenuBarExtra(currentNumber, systemImage: "\(currentNumber).circle") {
        MenuBarExtra("\(insecurePacketCount)", systemImage: "network.badge.shield.half.filled") {
        
            Button("\(action)") {
                if (!running) {
                    DispatchQueue.global(qos: .background).async {
                        tcpDumpWithPipe()
                    }
                    running = true;
                    action="Stop Capture";
                } else {
                    
                }
            }
            
//            Button("Stop Capture") {
//                self.currentNumber = "2"
//                print(insecurePacketCount)
//                //                appDelegate.quitApp()
//            }
            Divider()
            
            HStack {
                Text("Unsecure Packets: \(insecurePacketCount)")
                //                                    .font(.body)
                //                                Spacer()
                //                                Text("\(insecurePacketCount)")
                ////                                    .font(.body)
                ////                                    .frame(width: 40, alignment: .trailing)
            }
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        }
    }
    
    public func tcpDumpWithPipe() {
        //    let pipe = Pipe()  // Create an NSPipe equivalent in Swift
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent("my_temp_file.txt")
        do {
            try Data().write(to: tempFileURL, options: .atomic)
            //        print("File cleared: \(fileURL.path)")
        } catch {
            print("Error clearing file: \(error.localizedDescription)")
        }
        
        // Call the Objective-C method
        ProcessRunner.executeAdminProcess(withPipe: "/usr/sbin/tcpdump",
                                          arguments: [
                                            "-i", "any",
                                            "-s", "0",
                                            "port", "80"
                                            // ,"or",
                                            // "port", "443"
                                          ],
                                          pipe: tempFileURL)
        
        // Asynchronously read the output
        do {
            let readHandle = try FileHandle(forReadingFrom: tempFileURL)
            let writeHandle = try FileHandle(forWritingTo: tempFileURL)
            
            readHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                    // Split the data by lines
                    let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
                    
                    for line in lines {
                        print("\(line)")
                        //                        print(countPointer.pointee);
                        //                        countPointer.pointee += 1
                        DispatchQueue.main.async {
                            // Use the pointer value to update the state (insecurePacketCount)
                            //                           print("doing a thing")
                            insecurePacketCount += 1
                            //                            print("increment");
                            //                            MenuBarApp.objectWillChange.send()
                        }
                    }
                    
                    
                    // Move the file pointer to the beginning for rewriting
                    writeHandle.seek(toFileOffset: 0)
                    
                    // Remove processed lines and write the remainder
                    let remainingData = Data()
                    try? remainingData.write(to: tempFileURL, options: .atomic)
                }
            }
            
            // Keep the process running to read continuously
            // not working over long periods of time
            let timer = Timer(timeInterval: 2.0, repeats: true) { _ in }
            RunLoop.current.add(timer, forMode: .default)
            
            // Start the RunLoop
            RunLoop.current.run()
            
        } catch {
            print("Error handling file: \(error)")
        }
        
    }
    
}
