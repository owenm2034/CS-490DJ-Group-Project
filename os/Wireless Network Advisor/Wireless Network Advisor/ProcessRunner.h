//
//  processRunner.h
//  Wireless Network Advisor
//
//  Created by Owen Monus on 2024-11-24.
//

#ifndef processRunner_h
#define processRunner_h

#import <Foundation/Foundation.h>

@interface ProcessRunner : NSObject

/**
 Runs a shell script as an administrator.

 @param scriptPath The full path to the script to run.
 @param arguments An array of arguments to pass to the script.
 @param output A pointer to a string to capture the output of the script.
 @param errorDescription A pointer to a string to capture any error messages.
 @return YES if the script executes successfully, NO otherwise.
 */
- (BOOL)runProcessAsAdministrator:(NSString *)scriptPath
                    withArguments:(NSArray<NSString *> *)arguments
                           output:(NSString **)output
                 errorDescription:(NSString **)errorDescription;

@end

#endif /* processRunner_h */
