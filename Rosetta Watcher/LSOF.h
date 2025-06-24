//
//  LSOF.h
//  Rosetta Watcher
//
//  Created by Mejdej on 25/06/2025.
//

#import <Foundation/Foundation.h>
#import "sys/proc_info.h"

static const NSInteger ProcPidPathInfoMaxSize = PROC_PIDPATHINFO_MAXSIZE;

bool tryToElevatePrivileges(void);

NSArray<NSString *> *lsof(int pid);
