//
//  GifView.swift
//  Rosetta Watcher
//
//  Created by Mejdej on 25/06/2025.
//

import SwiftUI
import ImageIO
import AppKit

private typealias GIFFrameSwiftUI = (image: Image, duration: TimeInterval)
private typealias GIFFrameSwiftUICached = (forceSize: NSSize?, template: Bool, cache: [GIFFrameSwiftUI])

private struct GIFFrame {
    let image: CGImage
    let duration: TimeInterval
}

struct GIFView: View {
    private let images: [Image]
    private let durations: [TimeInterval]
    
    @State private var currentIndex = 0
    @State private var timer: Timer?
    private let speed: Double
    private var isRunning: Bool
    @State private var task: Task<Void, Error>?
    
    init(
        gifName: String,
        speed: Double = 1.0,
        isRunning: Bool = true,
        forceSize: NSSize? = nil,
        template: Bool = false
    ) {
        self.speed = speed
        self.isRunning = isRunning
        
        guard let imageFrames = loadGif(name: gifName, forceSize: forceSize, template: template) else {
            self.images = []
            self.durations = []
            return
        }
        self.images = imageFrames.map { $0.image }
        self.durations = imageFrames.map { $0.duration }
    }
    
    var body: some View {
        images[currentIndex]
            .resizable()
            .scaledToFit()
            .onAppear {
                startAnimation()
            }
            .onDisappear {
                task?.cancel()
            }
    }
    
    private func startAnimation() {
        guard isRunning else {
            task?.cancel()
            return
        }
        guard images.count > 1 else {
            return
        }
        
        task = Task { @MainActor in
            while true {
                currentIndex = (currentIndex + 1) % images.count
                try await Task.sleep(for: .milliseconds(1_000 * durations[currentIndex] / speed))
            }
        }
    }
}

private var gifCache: [String: GIFFrameSwiftUICached] = [:]

private func loadGif(
    name gifName: String,
    forceSize: NSSize?,
    template: Bool
) -> [GIFFrameSwiftUI]? {
    if let cached = gifCache[gifName],
       cached.forceSize == forceSize,
       cached.template == template {
        return cached.cache
    }
    
    guard let asset: NSDataAsset = NSDataAsset(name: gifName) else {
        return nil
    }
    let gifFrames: [GIFFrame] = asset.data.loadGIF()
    let imageFrames: [GIFFrameSwiftUI] = gifFrames.convertToSwiftUIImages(forceSize: forceSize, template: template)
    gifCache[gifName] = (forceSize, template, imageFrames)
    
    return imageFrames
}

extension Data {
    fileprivate func loadGIF() -> [GIFFrame] {
        guard let source: CGImageSource = CGImageSourceCreateWithData(self as CFData, nil) else {
            return []
        }
        
        let count: Int = CGImageSourceGetCount(source)
        var frames: [GIFFrame] = []
        
        for i in 0..<count {
            guard let image: CGImage = CGImageSourceCreateImageAtIndex(source, i, nil) else {
                continue
            }
            guard let properties: [CFString: Any] = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any] else {
                continue
            }
            guard let gifProperties: [CFString: Any] = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
                continue
            }
            
            let unclampedDelay: NSNumber? = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? NSNumber
            let delay: NSNumber? = gifProperties[kCGImagePropertyGIFDelayTime] as? NSNumber
            let duration: TimeInterval = unclampedDelay?.doubleValue ?? delay?.doubleValue ?? 0.1
            
            frames.append(GIFFrame(image: image, duration: duration))
        }
        
        return frames
    }
}

extension Array where Element == GIFFrame {
    fileprivate func convertToSwiftUIImages(
        forceSize: NSSize?,
        template: Bool
    ) -> [GIFFrameSwiftUI] {
        self.map { frame in
            let renderer: ImageRenderer = ImageRenderer(content: Image(decorative: frame.image, scale: 1.0))
            renderer.scale = 1
            
            let nsImage: NSImage = renderer.nsImage ?? NSImage()
            nsImage.isTemplate = template
            
            if let forceSize {
                nsImage.size = forceSize
            }
            return (Image(nsImage: nsImage), frame.duration)
        }
    }
}

#Preview {
    GIFView(gifName: "Rosetta", speed: 1.0, isRunning: true, forceSize: nil, template: false)
}
