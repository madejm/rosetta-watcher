//
//  MenuBarLabelView.swift
//  Rosetta Watcher
//
//  Created by Mejdej on 25/06/2025.
//

import SwiftUI

struct MenuBarLabelView: View {
    private enum Constant {
        static let size = NSSize(width: 20, height: 20)
    }
    
    @ObservedObject var model: ContentViewModel
    
    var body: some View {
        if model.processes.isEmpty {
            Image(nsImage: {
                let nsImage = NSImage(imageLiteralResourceName: "Rosetta0")
                nsImage.size = Constant.size
                nsImage.isTemplate = true
                return nsImage
            }())
        } else {
            GIFView(
                gifName: "Rosetta",
                speed: 2.0,
                isRunning: true,
                forceSize: Constant.size,
                template: true
            )
        }
    }
}
