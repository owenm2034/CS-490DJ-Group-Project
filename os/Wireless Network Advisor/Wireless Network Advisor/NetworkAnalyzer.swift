import Foundation

public func runTcpdump() {
    // Create an instance of the ProcessRunner
//    let processRunner = ProcessRunner()
    
    // Define variables to hold output and error messages
    var output: NSString?
    var errorDescription: NSString?
    
    // Call the Objective-C method
    let success = ProcessRunner.runProcess(
        asAdministrator: "/usr/bin/id",
            withArguments: ["-un"],
            output: &output,
            errorDescription: &errorDescription
        )
//    let success = processRunner.runProcess(
//        asAdministrator: "/usr/bin/sudo",
//        withArguments: [
//            "/usr/sbin/tcpdump",
//            "-i", "en0",
//            "-A",
//            "port", "80", "or", "port", "443"
//        ],
//        output: &output,
//        errorDescription: &errorDescription
//    )

    
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

public func tcpDumpWithPipe() {
    let pipe = Pipe()  // Create an NSPipe equivalent in Swift
    let tempDirectory = FileManager.default.temporaryDirectory
    let tempFileURL = tempDirectory.appendingPathComponent("my_temp_file.txt")
    
    // Call the Objective-C method
    ProcessRunner.executeAdminProcess(withPipe: "/usr/sbin/tcpdump",
                                      arguments: [
                                                    "-i", "en0",
                                                    "-A",
                                                    "port", "80", "or", "port", "443"
                                      ],
                                      pipe: tempFileURL)
    
    // Asynchronously read the output
    let readHandle = pipe.fileHandleForReading
    readHandle.readabilityHandler = { handle in
        let data = handle.availableData
        if let output = String(data: data, encoding: .utf8), !output.isEmpty {
            print("Output: \(output)")
        }
    }
}
