//
//  LSOF.m
//  Rosetta Watcher
//
//  Created by Mejdej on 25/06/2025.
//

#import <Foundation/Foundation.h>
#import "LSOF.h"

AuthorizationRef authRef = nil;

int elevatePrivileges(const char *toolPath) {
    #ifdef DEBUG
    if ([NSProcessInfo.processInfo.environment[@"XCODE_RUNNING_FOR_PREVIEWS"] isEqual:@"1"]) {
        return 0;
    }
    #endif
    
    if (authRef != nil) {
        return 0;
    }
    
    OSStatus status;
    
    // Create authorization reference
    status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authRef);
    if (status != errAuthorizationSuccess) {
        NSLog(@"AuthorizationCreate failed");
        authRef = nil;
        return -1;
    }
    
    // Request rights
    AuthorizationItem right = {kAuthorizationRightExecute, strlen(toolPath), (void *)toolPath, 0};
    AuthorizationRights rights = {1, &right};
    AuthorizationFlags flags = kAuthorizationFlagDefaults |
    kAuthorizationFlagInteractionAllowed |
    kAuthorizationFlagPreAuthorize |
    kAuthorizationFlagExtendRights;
    
    status = AuthorizationCopyRights(authRef, &rights, NULL, flags, NULL);
    if (status != errAuthorizationSuccess) {
        NSLog(@"AuthorizationCopyRights failed");
        authRef = nil;
        return -1;
    }
    
    return 0;
}

int runPrivilegedCommand(const char *toolPath, const char * const *args, NSMutableArray<NSString *> *result) {
    if (authRef == nil) {
        return -1;
    }
    
    OSStatus status;
    FILE *pipe = NULL;
    
    // Run the tool with elevated privileges
    status = AuthorizationExecuteWithPrivileges(authRef, toolPath, kAuthorizationFlagDefaults, args, &pipe);
    if (status != errAuthorizationSuccess) {
        NSLog(@"AuthorizationExecuteWithPrivileges failed");
        return status;
    }

    // Read output
    char buffer[1024];
    while (fgets(buffer, sizeof(buffer), pipe)) {
        NSString *string = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
        [result addObject:string];
    }

    fclose(pipe);
//    AuthorizationFree(authRef, kAuthorizationFlagDefaults);
    return 0;
}

const char *tool = "/usr/sbin/lsof";

bool tryToElevatePrivileges(void) {
    return elevatePrivileges(tool) == 0;
}

NSArray<NSString *> *lsof(int pid) {
    NSString *pidString = [NSString stringWithFormat: @"%d", pid];
    const char *cString = [pidString UTF8String];
    
    const char *args[] = {"-p", cString, NULL};
    
    NSMutableArray<NSString *> *result = [NSMutableArray new];
    
    runPrivilegedCommand(tool, args, result);
    
    return result;
}
