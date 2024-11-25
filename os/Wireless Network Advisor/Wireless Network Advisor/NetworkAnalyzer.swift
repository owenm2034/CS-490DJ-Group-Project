//
//  NetworkAnalyzer.swift
//  Wireless Network Advisor
//
//  Created by Owen Monus on 2024-11-19.
//

import Foundation

public func runTcpdump() {
    // Create an instance of the ProcessRunner
    let processRunner = ProcessRunner()
    
    // Define variables to hold output and error messages
    var output: NSString?
    var errorDescription: NSString?
    
    // Call the Objective-C method
    let success = processRunner.runProcess(
        asAdministrator: "/usr/bin/id",
            withArguments: ["-un"],
            output: &output,
            errorDescription: &errorDescription
        )
    
    // Handle the result
    if success {
        print("Process executed successfully.")
        if let outputString = output as String? {
            print("Output:\n\(outputString)")
        }
    } else {
        print("Process failed.")
        if let errorString = errorDescription as String? {
            print("Error: \(errorString)")
        }
    }
}
