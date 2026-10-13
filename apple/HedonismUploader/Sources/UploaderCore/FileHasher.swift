import CryptoKit
import Foundation

/// Hashes a file in chunks so 70 MB RAW files never sit in memory whole.
public enum FileHasher {
    public struct Digests: Equatable, Sendable {
        /// SHA-256, the photo's identity on the server (imageHash).
        public let sha256: Data
        /// MD5, which storage checks the upload against (Content-MD5).
        public let md5: Data
    }

    public static func digests(of url: URL, chunkSize: Int = 4 << 20) throws -> Digests {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        var sha = SHA256()
        var md5 = Insecure.MD5()
        while let chunk = try handle.read(upToCount: chunkSize), !chunk.isEmpty {
            sha.update(data: chunk)
            md5.update(data: chunk)
        }
        return Digests(sha256: Data(sha.finalize()), md5: Data(md5.finalize()))
    }
}
