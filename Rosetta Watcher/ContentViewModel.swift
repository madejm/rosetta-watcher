//
//  ContentViewModel.swift
//  Rosetta Watcher
//
//  Created by Mejdej on 24/06/2025.
//

import SwiftUI
import Combine

struct ProcessData {
    let pid: pid_t
    let path: String
    var openFiles: [String]
}

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var processes: [ProcessData] = []
    @Published var rootGranted: Bool
    private var timer: Timer?
    
    init() {
        self.rootGranted = tryToElevatePrivileges()
        
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateProcesses()
            }
        }
    }
    
    private func updateProcesses() {
        let processes: [ProcessData] = getAllRunningProcesses()
        let oahd: [ProcessData] = processes
            .filter {
                $0.path.hasSuffix("/oahd-helper")
            }
            .map {
                var process = $0
                let files: [String] = getOpenFiles(for: $0.pid)
                
                process.openFiles = files
                    .enumerated()
                    .filter {
                        // skip header
                        $0.offset != 0
                    }
                    .map { $0.element }
                    .compactMap {
                        guard let first = $0.firstRange(of: "/") else {
                            return nil
                        }
                        return String($0[first.lowerBound...])
                            .replacingOccurrences(of: "\n", with: "")
                    }
                    .reduce(into: Set<String>()) {
                        // remove duplicates
                        $0.insert($1)
                    }
                    .filter {
                        !$0.isEmpty
                        &&
                        $0 != "/"
                        &&
                        !$0.hasPrefix("/dev/")
                        &&
                        !$0.hasPrefix("/usr/")
                        &&
                        !$0.hasPrefix("/private/")
                    }
                return process
            }
        
        self.processes = oahd
    }
    
    private func getAllRunningProcesses() -> [ProcessData] {

        let maxProcesses: Int = 4096
        let pidSize: Int = MemoryLayout<pid_t>.stride
        let pidsPointer: UnsafeMutablePointer<pid_t> = UnsafeMutablePointer<pid_t>
            .allocate(capacity: maxProcesses)
        
        defer {
            pidsPointer.deallocate()
        }

        let numberOfPIDs: Int32 = proc_listallpids(pidsPointer, Int32(pidSize * maxProcesses))
        
        guard numberOfPIDs > 0 else {
            return []
        }
        
        var result: [ProcessData] = []
        
        for i in 0..<numberOfPIDs {
            let pid: pid_t = pidsPointer[Int(i)]
            var pathBuffer: [CChar] = [CChar](repeating: 0, count: ProcPidPathInfoMaxSize)
            let size: Int32 = proc_pidpath(pid, &pathBuffer, UInt32(pathBuffer.count))
            
            guard size > 0 else {
                continue
            }
            guard let path: String = String(cString: pathBuffer, encoding: .utf8) else {
                continue
            }
            result.append(.init(pid: pid, path: path, openFiles: []))
        }

        return result
    }
    
    private func getOpenFiles(for pid: pid_t) -> [String] {
        lsof(pid)
    }
}
