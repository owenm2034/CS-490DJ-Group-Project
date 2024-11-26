//
//  admin.m
//  Wireless Network Advisor
//
//  Created by Owen Monus on 2024-11-24.
//

#import <Foundation/Foundation.h>

#import "ProcessRunner.h"

//@implementation ProcessRunner
//
//- (BOOL)runProcessAsAdministrator:(NSString *)scriptPath
//                    withArguments:(NSArray<NSString *> *)arguments
//                           output:(NSString **)output
//                 errorDescription:(NSString **)errorDescription {
//
//    NSString *allArgs = [arguments componentsJoinedByString:@" "];
//    NSString *fullScript = [NSString stringWithFormat:@"%@ %@", scriptPath, allArgs];
//
//    NSDictionary *errorInfo = [NSDictionary new];
//    NSString *script = [NSString stringWithFormat:
//                        @"do shell script \"%@\" with administrator privileges"
//                        ,
//                        fullScript];
//
//    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
//    NSAppleEventDescriptor *eventResult = [appleScript executeAndReturnError:&errorInfo];
//
//    // Check errorInfo
//    if (!eventResult) {
//        // Describe common errors
//        *errorDescription = nil;
//        if ([errorInfo valueForKey:NSAppleScriptErrorNumber]) {
//            NSNumber *errorNumber = (NSNumber *)[errorInfo valueForKey:NSAppleScriptErrorNumber];
//            if ([errorNumber intValue] == -128)
//                *errorDescription = @"The administrator password is required to do this.";
//        }
//
//        // Set error message from provided message
//        if (*errorDescription == nil) {
//            if ([errorInfo valueForKey:NSAppleScriptErrorMessage]) {
//                *errorDescription = (NSString *)[errorInfo valueForKey:NSAppleScriptErrorMessage];
//            }
//        }
//
//        return NO;
//    } else {
//        // Set output to the AppleScript's output
//        *output = [eventResult stringValue];
//        return YES;
//    }
//}
//
//@end


@implementation ProcessRunner
+ (BOOL)runProcessAsAdministrator:(NSString *)scriptPath
                    withArguments:(NSArray<NSString *> *)arguments
                           output:(NSString **)output
                 errorDescription:(NSString **)errorDescription {

    // Join script path and arguments into a single command string
    NSString *allArgs = [arguments componentsJoinedByString:@" "];
    NSString *fullScriptCommand = [NSString stringWithFormat:@"%@ %@", scriptPath, allArgs];
    
    // Escape double quotes and backslashes for the AppleScript
    fullScriptCommand = [fullScriptCommand stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    fullScriptCommand = [fullScriptCommand stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];

    // Create the AppleScript that runs the shell command with administrator privileges
    NSString *appleScriptSource = [NSString stringWithFormat:
        @"do shell script \"%@\" with administrator privileges", fullScriptCommand];

    // Use osascript to run the AppleScript from the command line
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/osascript"];
    [task setArguments:@[@"-e", appleScriptSource]];

    // Capture output using NSPipe
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    [task setStandardError:outputPipe];

    NSFileHandle *fileHandle = [outputPipe fileHandleForReading];

    @try {
        [task launch];
    } @catch (NSException *exception) {
        *errorDescription = [NSString stringWithFormat:@"Failed to launch process: %@", exception.reason];
        return NO;
    }

    // Read the process output
    NSData *data = [fileHandle readDataToEndOfFile];
    [task waitUntilExit];  // Ensure the task completes

    if (data) {
        *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return ([task terminationStatus] == 0);  // Check if the task completed successfully
    } else {
        *errorDescription = @"No output captured from the process.";
        return NO;
    }
}

+ (BOOL)runProcessAsAdministratorPipeOutput:(NSString *)scriptPath
                    withArguments:(NSArray<NSString *> *)arguments
                                       pipe:(NSURL *)outputPipe  // Pass NSPipe pointer
                 errorDescription:(NSString **)errorDescription {
    
    /// notes for me tomorrow:
    ///     - write output to a temp file
    ///     - read that file in async
    ///     - do stuff
    ///     - win
    ///     - use FileManager.default.temporaryDirectory in swift to spawn a temp directory

    // Join script path and arguments into a single command string
    NSString *allArgs = [arguments componentsJoinedByString:@" "];
    NSString *fullScriptCommand = [NSString stringWithFormat:@"%@ %@", scriptPath, allArgs];

    // Escape double quotes and backslashes for the AppleScript
    fullScriptCommand = [fullScriptCommand stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    fullScriptCommand = [fullScriptCommand stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];

    // Create the AppleScript that runs the shell command with administrator privileges
    NSString *appleScriptSource = [NSString stringWithFormat:
                                   @"do shell script \"%@ > %@\" with administrator privileges", fullScriptCommand, outputPipe.path];

    // Use osascript to run the AppleScript from the command line
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/osascript"];
    [task setArguments:@[@"-e", appleScriptSource]];

    // Set provided NSPipe for standard output and error
//    [task setStandardOutput:outputPipe];
//    [task setStandardError:outputPipe];

    @try {
        [task launch];
    } @catch (NSException *exception) {
        *errorDescription = [NSString stringWithFormat:@"Failed to launch process: %@", exception.reason];
        return NO;
    }

    return YES;  // Task launched successfully, caller reads from the pipe
}

+ (void)executeAdminProcessWithPipe:(NSString *)scriptPath
                           arguments:(NSArray<NSString *> *)arguments
                                pipe:(NSURL *)outputPipe {
    
    // Launch the process asynchronously on a background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *errorDescription = nil;

        BOOL success = [self runProcessAsAdministratorPipeOutput:scriptPath
                                                   withArguments:arguments
                                                           pipe:outputPipe
                                               errorDescription:&errorDescription];

        if (!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Error: %@", errorDescription);
            });
        }
    });

    // Read the output from the pipe asynchronously on the main thread
//    NSFileHandle *readHandle = [outputPipe fileHandleForReading];
    NSLog(@"Process is reading the pipe");
    
    // Set up a block to read data when it becomes available
//    [readHandle setReadabilityHandler:^(NSFileHandle *handle) {
//        NSData *data = [handle availableData];
//        
//        if (data.length > 0) {
//            NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//            NSLog(@"Output: %@", output);  // Process or display output here
//        } else {
//            // End of data, clean up
//            [readHandle setReadabilityHandler:nil];
//        }
//    }];
}


@end


