//
//  admin.m
//  Wireless Network Advisor
//
//  Created by Owen Monus on 2024-11-24.
//

#import <Foundation/Foundation.h>

#import "ProcessRunner.h"

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
    [task waitUntilExit];

    if (data) {
        *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return ([task terminationStatus] == 0);
    } else {
        *errorDescription = @"No output captured from the process.";
        return NO;
    }
}

+ (BOOL)runProcessAsAdministratorPipeOutput:(NSString *)scriptPath
                    withArguments:(NSArray<NSString *> *)arguments
                                       pipe:(NSURL *)outputPipe
                 errorDescription:(NSString **)errorDescription {
    
    NSString *allArgs = [arguments componentsJoinedByString:@" "];
    NSString *fullScriptCommand = [NSString stringWithFormat:@"%@ %@", scriptPath, allArgs];

    fullScriptCommand = [fullScriptCommand stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    fullScriptCommand = [fullScriptCommand stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];

    NSString *appleScriptSource = [NSString stringWithFormat:
                                   @"do shell script \"%@ > %@\" with administrator privileges", fullScriptCommand, outputPipe.path];

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/osascript"];
    [task setArguments:@[@"-e", appleScriptSource]];

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
}


@end


