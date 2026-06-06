//
//  MediaPreloader.swift
//  LearnLock
//
//  Preloads remote GIF assets into an in-memory cache on app launch so the
//  mascot renders without any visible network delay.
//

import Foundation

/// Lightweight thread-safe in-memory cache for raw GIF bytes keyed by URL string.
final class GIFCache: @unchecked Sendable {
    static let shared = GIFCache()
    private var store: [String: Data] = [:]
    private let lock = NSLock()

    func data(for url: String) -> Data? {
        lock.lock(); defer { lock.unlock() }
        return store[url]
    }

    func set(_ data: Data, for url: String) {
        lock.lock(); defer { lock.unlock() }
        store[url] = data
    }
}

enum MediaPreloader {
    static let base = "https://pyikafpvphzqdadjvktz.supabase.co/storage/v1/object/public/LearnLock"

    /// All mascot/onboarding GIFs that should be ready before the user reaches
    /// the screens that show them.
    static var gifURLs: [String] {
        [
            "\(base)/HappyGIF.gif",
            "\(base)/ThinkingGIF.gif",
            "\(base)/DeterminedGIF.gif",
            "\(base)/SadGIF.gif",
            "\(base)/ExcitedGIF.gif",
            "\(base)/ProudGIF.gif",
            "\(base)/GlassesGIF.gif"
        ]
    }

    /// Kicks off background fetches for every GIF URL. Safe to call multiple
    /// times — already-cached URLs are skipped.
    static func preloadAll() {
        // Bump URLCache so AsyncImage benefits too.
        URLCache.shared.memoryCapacity = max(URLCache.shared.memoryCapacity, 64 * 1024 * 1024)
        URLCache.shared.diskCapacity = max(URLCache.shared.diskCapacity, 256 * 1024 * 1024)

        for s in gifURLs {
            guard let url = URL(string: s), GIFCache.shared.data(for: s) == nil else { continue }
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data else { return }
                GIFCache.shared.set(data, for: s)
            }.resume()
        }
    }
}
