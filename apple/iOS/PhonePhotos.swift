#if os(iOS)
import ImageIO
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import UploaderCore

/// Photos taken with the phone's camera or chosen from its library are copied here, then uploaded
/// from this folder through the same hash-checked CardUploader run a camera card uses.
enum PhoneStaging {
    static var folder: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Chip-phone-photos", isDirectory: true)
    }

    static var count: Int { CardScanner.photos(on: folder).count }

    /// Copies a file into the staging folder under a unique name. Shots are grouped by basename,
    /// so two library photos that are both IMG_0001 must not share one.
    static func store(_ source: URL, suggestedName: String?, type: UTType) throws -> URL {
        let target = try destination(suggestedName: suggestedName ?? source.lastPathComponent, type: type)
        try FileManager.default.copyItem(at: source, to: target)
        return target
    }

    static func destination(suggestedName: String, type: UTType) throws -> URL {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true,
                                                attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
        let base = (suggestedName as NSString).deletingPathExtension
        let name = (base.isEmpty ? "Photo" : base) + "-" + UUID().uuidString.prefix(8)
        return folder.appendingPathComponent(name).appendingPathExtension(type.preferredFilenameExtension ?? "jpg")
    }

    static func removeAll() {
        try? FileManager.default.removeItem(at: folder)
    }

    /// Writes an image and its metadata (capture time, orientation, camera details) as HEIC,
    /// falling back to JPEG where HEIC encoding is unavailable.
    static func write(_ image: CGImage, properties: [String: Any], suggestedName: String) throws -> URL {
        var options = properties
        options[kCGImageDestinationLossyCompressionQuality as String] = 0.92
        for type in [UTType.heic, .jpeg] {
            let url = try destination(suggestedName: suggestedName, type: type)
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil) else { continue }
            CGImageDestinationAddImage(destination, image, options as CFDictionary)
            if CGImageDestinationFinalize(destination) { return url }
            try? FileManager.default.removeItem(at: url)
        }
        throw CocoaError(.fileWriteUnknown)
    }

    /// Re-encodes image data the server does not accept (ProRAW DNG, GIF, WebP) with its metadata intact.
    static func convert(_ data: Data, suggestedName: String) throws -> URL {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { throw CocoaError(.fileReadCorruptFile) }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] ?? [:]
        return try write(image, properties: properties, suggestedName: suggestedName)
    }
}

/// A library photo, received as its original file when the server accepts that format.
struct PickedPhoto: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .heic) { PickedPhoto(url: try PhoneStaging.store($0.file, suggestedName: nil, type: .heic)) }
        FileRepresentation(importedContentType: .heif) { PickedPhoto(url: try PhoneStaging.store($0.file, suggestedName: nil, type: .heif)) }
        FileRepresentation(importedContentType: .jpeg) { PickedPhoto(url: try PhoneStaging.store($0.file, suggestedName: nil, type: .jpeg)) }
        FileRepresentation(importedContentType: .png) { PickedPhoto(url: try PhoneStaging.store($0.file, suggestedName: nil, type: .png)) }
        DataRepresentation(importedContentType: .image) { PickedPhoto(url: try PhoneStaging.convert($0, suggestedName: "Photo")) }
    }
}

/// Take-photo and photo-library buttons for the upload screen.
struct PhonePhotoButtons: View {
    @ObservedObject var model: MobileUploadModel
    @State private var items: [PhotosPickerItem] = []
    @State private var importing = false
    @State private var takingPhoto = false

    var body: some View {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            Button("Take photo") { takingPhoto = true }
                .disabled(model.running || importing)
                .fullScreenCover(isPresented: $takingPhoto) {
                    CameraCapture { image, metadata in
                        takingPhoto = false
                        guard let image else { return }
                        save(image, metadata: metadata)
                    }
                    .ignoresSafeArea()
                }
        }
        PhotosPicker(selection: $items, matching: .images, preferredItemEncoding: .current) {
            Text(importing ? "Adding photos…" : "Choose from photo library")
        }
        .disabled(model.running || importing)
        .onChange(of: items) { selection in
            guard !selection.isEmpty else { return }
            Task { await add(selection) }
        }
        let staged = model.running ? 0 : PhoneStaging.count
        if staged > 0 {
            Button("Remove \(staged) phone photo\(staged == 1 ? "" : "s")", role: .destructive) {
                PhoneStaging.removeAll()
                refresh()
            }
        }
    }

    private func add(_ selection: [PhotosPickerItem]) async {
        importing = true
        var failed = 0
        for item in selection {
            do {
                if try await item.loadTransferable(type: PickedPhoto.self) == nil { failed += 1 }
            } catch { failed += 1 }
        }
        items = []
        importing = false
        refresh(failed: failed)
    }

    private func save(_ image: UIImage, metadata: [String: Any]) {
        do {
            guard let cgImage = image.cgImage else { throw CocoaError(.fileWriteUnknown) }
            var properties = metadata
            // The camera hands over the unrotated sensor image; the orientation tag rotates it.
            properties[kCGImagePropertyOrientation as String] = CGImagePropertyOrientation(image.imageOrientation).rawValue
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd-HHmmss"
            _ = try PhoneStaging.write(cgImage, properties: properties, suggestedName: "Chip-" + formatter.string(from: Date()))
            refresh()
        } catch {
            model.status = "Could not save the photo: \(error.localizedDescription)"
        }
    }

    private func refresh(failed: Int = 0) {
        model.usePhonePhotos()
        if failed > 0 { model.status += ". \(failed) photo\(failed == 1 ? "" : "s") could not be added." }
    }
}

/// The system camera, returning the captured image and its EXIF metadata.
struct CameraCapture: UIViewControllerRepresentable {
    let completion: (UIImage?, [String: Any]) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completion: (UIImage?, [String: Any]) -> Void
        init(completion: @escaping (UIImage?, [String: Any]) -> Void) { self.completion = completion }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            completion(info[.originalImage] as? UIImage, info[.mediaMetadata] as? [String: Any] ?? [:])
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { completion(nil, [:]) }
    }
}

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
#endif
