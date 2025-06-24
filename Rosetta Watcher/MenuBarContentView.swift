//
//  MenuBarContentView.swift
//  Rosetta Watcher
//
//  Created by Mejdej on 25/06/2025.
//

import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var model: ContentViewModel
    
    var body: some View {
        VStack {
            if !model.rootGranted {
                Text("Root privilege is not granted!")
                Button("Grant root permission") {
                    model.rootGranted = tryToElevatePrivileges()
                }
                Divider()
            }
            
            if model.processes.isEmpty {
                Text("No oahd-helper running.")
            } else {
                ForEach(Array(model.processes.enumerated()), id:\.offset) { process in
                    Button("Process pid: \(process.element.pid)") {}
                    
                    ForEach(Array(process.element.openFiles.enumerated()), id:\.offset) { file in
                        Text(file.element)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
