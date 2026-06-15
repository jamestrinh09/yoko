//
//  AnimatedGIFView.swift
//  LearnLock
//
//  Native ImageIO-backed GIF view. Decodes animated GIFs into a UIImage and
//  crossfades between them when the URL changes, so swapping mascots looks like
//  one continuous animation with no blank flash between frames.
//

import SwiftUI
import ImageIO
import UIKit

struct AnimatedGIFView: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> GIFImageView {
        let view = GIFImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.backgroundColor = .clear
        // The decoded GIF has a large intrinsic size (e.g. 904x1016). Without
        // dropping these priorities, Auto Layout forces the UIImageView to that
        // intrinsic size and the SwiftUI .frame is ignored — which is why every
        // size change previously had no visible effect. Letting the content
        // hug/compress freely makes the SwiftUI frame authoritative.
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.load(urlString)
        return view
    }

    func updateUIView(_ uiView: GIFImageView, context: Context) {
        uiView.load(urlString)
    }

    /// Reports the exact size SwiftUI proposes (the `.frame`) instead of the
    /// GIF's intrinsic pixel size, so the on-screen footprint always matches
    /// the requested frame.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: GIFImageView, context: Context) -> CGSize? {
        proposal.replacingUnspecifiedDimensions()
    }
}

final class GIFImageView: UIImageView {
    private var currentURL: String?

    // Returning a neutral intrinsic size prevents the large decoded GIF
    // dimensions from inflating layout when the SwiftUI frame is the source of
    // truth.
    override var intrinsicContentSize: CGSize { .zero }

    func load(_ urlString: String) {
        guard currentURL != urlString else { return }
        currentURL = urlString

        if let data = GIFCache.shared.data(for: urlString) {
            apply(data: data)
            return
        }
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data else { return }
            GIFCache.shared.set(data, for: urlString)
            Task { @MainActor [weak self] in
                guard let self, self.currentURL == urlString else { return }
                self.apply(data: data)
            }
        }.resume()
    }

    private func apply(data: Data) {
        guard let decoded = UIImage.animatedGIF(data: data) else { return }
        if image == nil {
            image = decoded
        } else {
            // Crossfade keeps the previous animation visible until the new one
            // is ready — eliminating the empty flash between mascot swaps.
            UIView.transition(
                with: self,
                duration: 0.28,
                options: [.transitionCrossDissolve, .allowUserInteraction]
            ) {
                self.image = decoded
            }
        }
    }
}

extension UIImage {
    /// Decodes raw GIF bytes into an animated `UIImage`. Falls back to a static
    /// image for single-frame data.
    static func animatedGIF(data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return UIImage(data: data)
        }
        let count = CGImageSourceGetCount(source)
        guard count > 1 else { return UIImage(data: data) }

        var frames: [UIImage] = []
        var totalDuration: Double = 0
        for index in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            frames.append(UIImage(cgImage: cgImage))
            totalDuration += frameDuration(source: source, index: index)
        }
        if totalDuration <= 0 { totalDuration = Double(count) * 0.1 }
        return UIImage.animatedImage(with: frames, duration: totalDuration)
    }

    private static func frameDuration(source: CGImageSource, index: Int) -> Double {
        guard
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
            let gif = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        else { return 0.1 }
        let unclamped = gif[kCGImagePropertyGIFUnclampedDelayTime] as? Double
        let clamped = gif[kCGImagePropertyGIFDelayTime] as? Double
        let duration = unclamped ?? clamped ?? 0.1
        return duration < 0.02 ? 0.1 : duration
    }
}
