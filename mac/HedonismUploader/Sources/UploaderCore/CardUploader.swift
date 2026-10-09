import Foundation

/// Uploads missing card contents through the standard photo-promise upload flow.
/// The server chooses the destination unless an explicit shoot context is supplied.
public final class CardUploader: @unchecked Sendable {
    public struct Progress: Codable, Equatable, Sendable {
        public var totalFiles: Int
        public var uploadedFiles: Int
        public var failedFiles: Int
        public var currentFile: String?
    }

    private let client: HedonismClient
    private let ledger: UploadLedger
    private let context: UploadContext?

    public init(client: HedonismClient, ledger: UploadLedger, context: UploadContext? = nil) {
        self.client = client
        self.ledger = ledger
        self.context = context
    }

    /// Uploads the card's new files, reporting progress after each file. Throws only for problems
    /// that stop the whole run (bad token, server down); a single failed file is counted and skipped.
    public func upload(volume: URL, progress: @escaping @Sendable (Progress) -> Void) async throws -> Progress {
        // Read and hash the whole card before creating promises or transmitting any file bytes.
        // Filename/size/mtime ledger entries cannot prove that the content is unchanged.
        let files = CardScanner.photos(on: volume)
        var hashes: [PhotoFile: FileHasher.Digests] = [:]
        for file in files {
            try Task.checkCancellation()
            progress(Progress(totalFiles: files.count, uploadedFiles: 0, failedFiles: 0, currentFile: "Checking " + file.filename))
            hashes[file] = try FileHasher.digests(of: file.url)
        }
        let uploaded = try await client.uploadedHashes(files.compactMap { hashes[$0]?.sha256 })
        var seen = uploaded
        let missing = files.filter { file in
            guard let hash = hashes[file]?.sha256 else { return false }
            return seen.insert(hash).inserted
        }
        let shots = CardScanner.shots(missing)
        var state = Progress(totalFiles: missing.count, uploadedFiles: 0, failedFiles: 0)
        progress(state)

        if !shots.isEmpty {
            let promiseID = try await client.createPromise(albumName: context?.albumName, context: context)
            for shot in shots {
                try Task.checkCancellation()
                let hashed = shot.map { file in (file, hashes[file]!) }
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
