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
    @StateObject private var viewModel = ProtocolStateViewModel()

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
                    ForEach(
                        viewModel.protocolStates.sorted(by: { $0.key < $1.key }
                        ),
                        id: \.key
                    ) { protocolName, protocolInfo in
                        Button(action: {
                            // Toggle the protocol's isEnabled value
                            viewModel.toggleProtocolState(
                                protocolName: protocolName)
                        }) {
                            HStack {
                                Text(
                                    "\(protocolName) (Port \(protocolInfo.port))"
                                )
                                Spacer()
                                // Add a checkmark based on the toggle state
                                if protocolInfo.isEnabled {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }

                    Divider()
                    Button(action: {
                        showPortNums.toggle()
                    }) {
                        Label(
                            showPortNums
                                ? "Hide Port Numbers " : "Show Port Numbers",
                            systemImage: showPortNums ? "checkmark" : ""
                        )
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
        }  //.onChange(of: protocolStates) { _ in
        // saveProtocolStates(protocolStates)
        //}
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

        var arguments: [String] = [
            "-i", "any",
            "-s", "0",
        ]

        //        let enabledPorts = protocolStates.filter { $0.value.isEnabled }.map {
        //            "\($0.value.port)"
        //        }
        //        if !enabledPorts.isEmpty {
        //            for (index, port) in enabledPorts.enumerated() {
        //                arguments.append(contentsOf: ["port", port])
        //                if index != enabledPorts.count - 1 {
        //                    arguments.append("or")
        //                }
        //            }
        //        }

        let enabledPorts = viewModel.protocolStates.filter {
            $0.value.isEnabled
        }.map { "\($0.value.port)" }

        if !enabledPorts.isEmpty {
            // Start building the arguments with "port" and the first port
            arguments.append(contentsOf: ["port", enabledPorts[0]])

            // Loop through the rest of the enabled ports, appending "or" between them
            for port in enabledPorts.dropFirst() {
                arguments.append("or")
                arguments.append("port")
                arguments.append(port)
            }
        }

        // Call the Objective-C method
        ProcessRunner.executeAdminProcess(
            withPipe: "/usr/sbin/tcpdump",
            arguments: arguments,
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

//    private func binding(for protocolName: String) -> Binding<Bool> {
//        Binding(
//            get: { protocolStates[protocolName]?.isEnabled ?? false },
//            set: { protocolStates[protocolName]?.isEnabled = $0 }
//        )
//    }
}
