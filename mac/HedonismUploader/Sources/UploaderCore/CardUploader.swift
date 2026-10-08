import Foundation

/// Uploads every new shot on a card: one upload batch per capture date, into an album named
/// "<prefix> <yyyy-MM-dd>", skipping files the ledger already has.
public final class CardUploader: @unchecked Sendable {
    public struct Progress: Equatable, Sendable {
        public var totalFiles: Int
        public var uploadedFiles: Int
        public var failedFiles: Int
        public var currentFile: String?
    }

    private let client: HedonismClient
    private let ledger: UploadLedger
    private let albumPrefix: String
    private let calendar: Calendar
    private let context: UploadContext?

    public init(client: HedonismClient, ledger: UploadLedger, albumPrefix: String, calendar: Calendar = .current, context: UploadContext? = nil) {
        self.client = client
        self.ledger = ledger
        self.albumPrefix = albumPrefix
        self.calendar = calendar
        self.context = context
    }

    public func albumName(for date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let day = String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
        return albumPrefix.isEmpty ? day : "\(albumPrefix) \(day)"
    }

    /// Files on the card not uploaded yet, grouped into shots and then by album.
    public func pendingShots(on volume: URL) -> [(album: String, shots: [[PhotoFile]])] {
        let files = CardScanner.photos(on: volume).filter { !ledger.contains($0) }
        var order: [String] = []
        var byAlbum: [String: [[PhotoFile]]] = [:]
        for shot in CardScanner.shots(files) {
            let album = context?.albumName ?? albumName(for: shot[0].modified)
            if byAlbum[album] == nil { order.append(album) }
            byAlbum[album, default: []].append(shot)
        }
        return order.map { (album: $0, shots: byAlbum[$0] ?? []) }
    }

    /// Uploads the card's new files, reporting progress after each file. Throws only for problems
    /// that stop the whole run (bad token, server down); a single failed file is counted and skipped.
    public func upload(volume: URL, progress: @escaping @Sendable (Progress) -> Void) async throws -> Progress {
        let batches = pendingShots(on: volume)
        var state = Progress(totalFiles: batches.reduce(0) { $0 + $1.shots.joined().count }, uploadedFiles: 0, failedFiles: 0)
        progress(state)

        for batch in batches {
            let promiseID = try await client.createPromise(albumName: batch.album, context: context)
            for shot in batch.shots {
                try Task.checkCancellation()
                let hashed = try shot.map { file in (file, try FileHasher.digests(of: file.url)) }
                let pending = try await client.attach(promiseID: promiseID, files: hashed)

                for (file, target) in zip(shot, pending) {
                    try Task.checkCancellation()
                    state.currentFile = file.filename
                    progress(state)
                    do {
                        try await client.upload(file, to: target)
                        try await client.finish(target, succeeded: true)
                        try ledger.record(file)
                        state.uploadedFiles += 1
                    } catch is CancellationError {
                        throw CancellationError()
                    } catch let error as HedonismClientError where error.isFatal {
                        throw error
                    } catch {
                        try Task.checkCancellation()
                        try? await client.finish(target, succeeded: false)
                        state.failedFiles += 1
                    }
                    progress(state)
                }
            }
        }
        state.currentFile = nil
        progress(state)
        return state
    }
}

extension HedonismClientError {
    /// Errors that will hit every file, so the run should stop instead of skipping files.
    var isFatal: Bool {
        if case let .http(status, _) = self { return status == 401 || status == 403 || status >= 500 }
        return false
    }
}
