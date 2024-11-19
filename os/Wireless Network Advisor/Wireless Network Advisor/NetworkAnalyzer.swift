//
//  NetworkAnalyzer.swift
//  Wireless Network Advisor
//
//  Created by Owen Monus on 2024-11-19.
//

import Foundation

struct Analyzer {
    private let process = Process()
    private let pipe = Pipe()
    
    func start() {
//        process.executableURL = URL(fileURLWithPath: "/usr/sbin/tcpdump")
//        process.standardOutput = pipe
//        process.standardError = pipe
//        process.arguments = ["-i", "en0", "-A", "port", "80", "or", "port", "443"]
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")  // Use sudo
        process.standardOutput = pipe
        process.standardError = pipe
        process.arguments = ["/usr/sbin/tcpdump", "-i", "en0", "-A", "port", "80", "or", "port", "443"]
        
//        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")  // Use sudo
//        process.standardOutput = pipe
//        process.standardError = pipe
//        process.arguments = ["/usr/sbin/tcpdump", "-i", "en0", "-A", "port", "80", "or", "port", "443"]
//
//        // Set environment to ensure sudo asks for a password
//        process.environment = ["SUDO_ASKPASS": "/usr/libexec/askpass"]
//        
//        // Ensure the user is prompted for their password
//        process.launchPath = "/usr/bin/sudo"
        
        do {
            try process.run()
            print("tcpdump started successfully.")
            
            // Capture and process the output in real-time
            let handle = pipe.fileHandleForReading
            handle.readabilityHandler = { fileHandle in
                if let output = String(data: fileHandle.availableData, encoding: .utf8) {
                    self.processOutput(output)
                }
            }
        } catch {
            print("Failed to run tcpdump: \(error)")
        }
    }
    
    func stop() {
        process.terminate()
        print("tcpdump stopped.")
    }
    
    private func processOutput(_ output: String) {
        // Add logic to analyze the tcpdump output
        print("Captured Output: \(output)")
        
        // Example detection: Check for HTTP connections
        if output.contains("http://") {
            print("Unsecure HTTP connection detected!")
        }
        
        // Example detection: Check for raw IP addresses in the payload
        let ipRegex = #"((\d{1,3}\.){3}\d{1,3})"#
        if let _ = output.range(of: ipRegex, options: .regularExpression) {
            print("Raw IP address detected in request.")
        }
        
        // Add further analysis as needed (e.g., HTTPS validation, local addresses)
    }
}

