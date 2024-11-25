//
//  admin.m
//  Wireless Network Advisor
//
//  Created by Owen Monus on 2024-11-24.
//

#import <Foundation/Foundation.h>

#import "ProcessRunner.h"

@implementation ProcessRunner

- (BOOL)runProcessAsAdministrator:(NSString *)scriptPath
                    withArguments:(NSArray<NSString *> *)arguments
                           output:(NSString **)output
                 errorDescription:(NSString **)errorDescription {

    NSString *allArgs = [arguments componentsJoinedByString:@" "];
    NSString *fullScript = [NSString stringWithFormat:@"%@ %@", scriptPath, allArgs];

    NSDictionary *errorInfo = [NSDictionary new];
    NSString *script = [NSString stringWithFormat:
                        @"do shell script \"%@\" with administrator privileges"
                        ,
                        fullScript];

    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
    NSAppleEventDescriptor *eventResult = [appleScript executeAndReturnError:&errorInfo];

    // Check errorInfo
    if (!eventResult) {
        // Describe common errors
        *errorDescription = nil;
        if ([errorInfo valueForKey:NSAppleScriptErrorNumber]) {
            NSNumber *errorNumber = (NSNumber *)[errorInfo valueForKey:NSAppleScriptErrorNumber];
            if ([errorNumber intValue] == -128)
                *errorDescription = @"The administrator password is required to do this.";
        }

        // Set error message from provided message
        if (*errorDescription == nil) {
            if ([errorInfo valueForKey:NSAppleScriptErrorMessage]) {
                *errorDescription = (NSString *)[errorInfo valueForKey:NSAppleScriptErrorMessage];
            }
        }

        return NO;
    } else {
        // Set output to the AppleScript's output
        *output = [eventResult stringValue];
        return YES;
    }
}

@end

