//
//  MenuBar.swift
//  Wireless Network Advisor
//
//  Created by Owen Monus on 2024-11-19.
//

import Cocoa
import CoreData
import SwiftUI

@main
struct MenuBarApp: App {
    @State var currentNumber: String = "1"
    @State var unsecurePacketCount: Int = 0
    @State var scannedPackets: Int = 0
    @State var running = false
    @State var action = "Start Capture"
    @State private var protocolStates: [String: ProtocolInfo] = [
        "HTTP": ProtocolInfo(isEnabled: true, port: 80),
        "FTP": ProtocolInfo(isEnabled: false, port: 21),
        "Telnet": ProtocolInfo(isEnabled: false, port: 23),
        "SMTP": ProtocolInfo(isEnabled: false, port: 25),
        "Time": ProtocolInfo(isEnabled: false, port: 37),
        "DNS": ProtocolInfo(isEnabled: false, port: 53),
        "IMAP": ProtocolInfo(isEnabled: false, port: 143),
        "SMB": ProtocolInfo(isEnabled: false, port: 445),
        "LDAP": ProtocolInfo(isEnabled: false, port: 389),
    ]

    @State private var showPortNums = false

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ScannedPackedInfo")  // Your .xcdatamodeld file name
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }
        return container
    }()

    var body: some Scene {
        MenuBarExtra(
            "\(unsecurePacketCount)",
            systemImage: "network.badge.shield.half.filled"
        ) {

            Button("\(action)") {
                if !running {
                    DispatchQueue.global(qos: .background).async {
                        tcpDumpWithPipe()
                    }
                    running = true
                    action = "Stop Capture"
                } else {

                }
            }

            if !running {
                Menu("Select Protocols") {
                    ForEach(protocolStates.sorted(by: { $0.key < $1.key }), id: \.key) {
                        protocolName, protocolInfo in
                        Toggle(isOn: binding(for: protocolName)) {
                            if showPortNums {
                                Text("\(protocolName): \(protocolInfo.port)")
                            } else {
                                Text(protocolName)
                            }
                        }
                    }
                    Divider()
                    Button(action: {
                        showPortNums.toggle()
                    }) {
                        Label(
                            showPortNums ? "Hide Port Numbers ": "Show Port Numbers",
                            systemImage: showPortNums ? "checkmark" : "")
                    }
                }
                .menuStyle(BorderlessButtonMenuStyle())  // Optional styling
                .padding()
            }


            Divider()

            HStack {
                Text("Unsecure Packets: \(unsecurePacketCount)")
                Text("Packets Scanned: \(scannedPackets)")
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        }
    }

    public func tcpDumpWithPipe() {
        //    let pipe = Pipe()  // Create an NSPipe equivalent in Swift
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent(
            "my_temp_file.txt")
        let regex = try! NSRegularExpression(
            pattern: #"^(\d{2}:\d{2}:\d{2}\.\d+).*?\b(\w+)(?=\s*>\s*\S+\.\d+:)"#
        )

        do {
            try Data().write(to: tempFileURL, options: .atomic)
        } catch {
            print("Error clearing file: \(error.localizedDescription)")
        }

        // Call the Objective-C method
        ProcessRunner.executeAdminProcess(
            withPipe: "/usr/sbin/tcpdump",
            arguments: [
                "-i", "any",
                "-s", "0",
                "port", "80", "or",
                "port", "443",
            ],
            pipe: tempFileURL)

        // Asynchronously read the output
        do {
            let readHandle = try FileHandle(forReadingFrom: tempFileURL)
            let writeHandle = try FileHandle(forWritingTo: tempFileURL)

            readHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if let output = String(data: data, encoding: .utf8),
                    !output.isEmpty
                {
                    // Split the data by lines
                    let lines = output.components(separatedBy: .newlines).filter
                    { !$0.isEmpty }

                    for line in lines {
                        if let match = regex.firstMatch(
                            in: line,
                            range: NSRange(line.startIndex..., in: line))
                        {
                            let dateRange = Range(match.range(at: 1), in: line)!
                            let protocolRange = Range(
                                match.range(at: 2), in: line)!

                            let date = line[dateRange]
                            let protoc = line[protocolRange]
                            print("\(date) + \(protoc) + \(line)")

                            if unsecurePacketCount % 500 == 1 {
                                scheduleNotification(
                                    date: String(date), ptc: String(protoc))
                            }
                            DispatchQueue.main.async {
                                unsecurePacketCount += 1
                            }
                        }

                        DispatchQueue.main.async {
                            scannedPackets += 1
                        }
                    }

                    writeHandle.seek(toFileOffset: 0)

                    // Remove processed lines and write the remainder
                    let remainingData = Data()
                    try? remainingData.write(to: tempFileURL, options: .atomic)
                }
            }

            // Keep the process running to read continuously
            // not working over long periods of time...?
            let timer = Timer(timeInterval: 2.0, repeats: true) { _ in }
            RunLoop.current.add(timer, forMode: .default)
            RunLoop.current.run()
        } catch {
            DispatchQueue.main.async {
                print("Error handling file: \(error)")
            }
        }

    }

    private func binding(for protocolName: String) -> Binding<Bool> {
        Binding(
            get: { protocolStates[protocolName]?.isEnabled ?? false },
            set: { protocolStates[protocolName]?.isEnabled = $0 }
        )
    }
}

struct ProtocolInfo {
    var isEnabled: Bool
    var port: Int
}
