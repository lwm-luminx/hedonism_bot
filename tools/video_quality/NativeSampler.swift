import AVFoundation
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers
import Vision

// Deliberately a separate executable: a failed vendor decoder cannot take down the batch.
struct Failure: Error, CustomStringConvertible {
    let description: String
    init(_ message: String) { description = message }
}

func writeJSON(_ value: Any, to url: URL) throws {
    try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys])
        .write(to: url, options: .atomic)
}

func fourCC(_ value: FourCharCode) -> String {
    String(bytes: [24, 16, 8, 0].map { UInt8((value >> $0) & 255) }, encoding: .ascii) ?? "unknown"
}

@main
struct NativeSampler {
    static func main() async {
        do { try await run() }
        catch {
            FileHandle.standardError.write(Data("Native decoder: \(error)\n".utf8))
            exit(1)
        }
    }

    static func run() async throws {
        let args = CommandLine.arguments
        guard args.count == 8,
              let start = Double(args[3]), let duration = Double(args[4]),
              let fps = Double(args[5]), let side = Int(args[6]),
              start.isFinite, duration.isFinite, fps.isFinite,
              start >= 0, duration > 0, fps > 0, side >= 64 else {
            throw Failure("Usage: native-sampler INPUT OUTPUT START DURATION FPS MAX_SIDE auto|bgra|half")
        }
        let source = URL(fileURLWithPath: args[1]).standardizedFileURL
        let output = URL(fileURLWithPath: args[2])
        let framesURL = output.appendingPathComponent("frames")
        guard !FileManager.default.fileExists(atPath: framesURL.path) else {
            throw Failure("Refusing to overwrite frames: \(framesURL.path)")
        }
        try FileManager.default.createDirectory(at: framesURL, withIntermediateDirectories: true)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let context = CIContext(options: [.outputColorSpace: colorSpace])
        var frames: [[String: Any]] = []
        var previousImage: CGImage?
        let began = Date()

        func save(_ input: CIImage, seconds: Double) throws {
            let extent = input.extent
            let normalized = input.transformed(by: CGAffineTransform(translationX: -extent.minX, y: -extent.minY))
            let scale = min(1, CGFloat(side) / max(extent.width, extent.height))
            let resized = normalized.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            guard let cg = context.createCGImage(resized, from: resized.extent.integral,
                                                 format: .RGBA8, colorSpace: colorSpace) else {
                throw Failure("Could not render decoded frame at \(seconds)")
            }
            let name = String(format: "%06d", frames.count)
            let jpeg = framesURL.appendingPathComponent(name + ".jpg")
            guard let dest = CGImageDestinationCreateWithURL(jpeg as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
                throw Failure("Cannot create JPEG")
            }
            CGImageDestinationAddImage(dest, cg, [kCGImageDestinationLossyCompressionQuality: 0.95] as CFDictionary)
            guard CGImageDestinationFinalize(dest) else { throw Failure("JPEG write failed") }
            let width = cg.width, height = cg.height
            var gray = [UInt8](repeating: 0, count: width * height)
            try gray.withUnsafeMutableBytes { bytes in
                guard let ctx = CGContext(data: bytes.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width,
                                          space: CGColorSpaceCreateDeviceGray(), bitmapInfo: 0) else {
                    throw Failure("Cannot create grayscale context")
                }
                ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
            }
            var pgm = Data("P5\n\(width) \(height)\n255\n".utf8)
            pgm.append(contentsOf: gray)
            try pgm.write(to: framesURL.appendingPathComponent(name + ".pgm"))
            var row: [String: Any] = ["time": seconds, "image": "frames/\(name).jpg",
                                      "gray": "frames/\(name).pgm", "width": width, "height": height]
            if let previous = previousImage {
                do {
                    let registration = VNTranslationalImageRegistrationRequest(targetedCGImage: previous, options: [:])
                    try VNImageRequestHandler(cgImage: cg, options: [:]).perform([registration])
                    if let translation = registration.results?.first?.alignmentTransform {
                        row["registration_translation_pixels"] = [translation.tx, translation.ty]
                    }
                } catch {
                    row["registration_error"] = String(describing: error)
                }
            }
            previousImage = cg
            do {
                let request = VNDetectFaceCaptureQualityRequest()
                try VNImageRequestHandler(cgImage: cg, options: [:]).perform([request])
                row["faces"] = (request.results ?? []).map { face -> [String: Any] in
                    let box = face.boundingBox
                    // Convert Vision's bottom-left coordinates to top-left image coordinates.
                    return ["box": [box.minX, 1 - box.maxY, box.width, box.height],
                            "quality": face.faceCaptureQuality as Any? ?? NSNull()]
                }
            } catch {
                row["faces"] = []
                row["vision_error"] = String(describing: error)
            }
            frames.append(row)
        }

        var metadata: [String: Any] = ["source": source.path, "decoder": "AVFoundation/CoreImage",
            "render": "Apple default development, CoreImage sRGB RGBA8; exposure is rendered, not sensor RAW",
            "sample_fps": fps, "max_side": side]
        if ["arw", "dng", "nef", "cr2", "cr3"].contains(source.pathExtension.lowercased()) {
            guard start == 0 else { throw Failure("Still images require --start 0") }
            guard let raw = CIFilter(imageURL: source, options: nil),
                  let image = raw.outputImage else {
                throw Failure("Apple CoreImage cannot develop this camera's RAW still")
            }
            try save(image, seconds: 0)
            metadata["kind"] = "still"
            metadata["duration"] = 0
            metadata["start"] = 0
            metadata["end"] = 0
            metadata["codec"] = source.pathExtension.lowercased()
        } else {
            let asset = AVURLAsset(url: source)
            guard let track = try await asset.loadTracks(withMediaType: .video).first else {
                throw Failure("No readable video track; a vendor RAW decoder or local proxy may be required")
            }
            let assetDuration = try await asset.load(.duration).seconds
            guard assetDuration.isFinite, start < assetDuration else { throw Failure("Start is outside the video") }
            let end = min(assetDuration, start + duration)
            let descriptions = try await track.load(.formatDescriptions)
            let codec = descriptions.first.map { fourCC(CMFormatDescriptionGetMediaSubType($0)) } ?? "unknown"
            let raw = ["aprn", "aprh"].contains(codec)
            let pixel: OSType
            switch args[7] {
            case "auto": pixel = raw ? kCVPixelFormatType_64RGBAHalf : kCVPixelFormatType_32BGRA
            case "half": pixel = kCVPixelFormatType_64RGBAHalf
            case "bgra": pixel = kCVPixelFormatType_32BGRA
            default: throw Failure("Unknown pixel format: \(args[7])")
            }
            let transform = try await track.load(.preferredTransform)
            let sourceFPS = try await track.load(.nominalFrameRate)
            let reader = try AVAssetReader(asset: asset)
            reader.timeRange = CMTimeRange(start: CMTime(seconds: start, preferredTimescale: 600000),
                                           duration: CMTime(seconds: end - start, preferredTimescale: 600000))
            let stream = AVAssetReaderTrackOutput(track: track,
                outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: pixel])
            stream.alwaysCopiesSampleData = false
            guard reader.canAdd(stream) else { throw Failure("Decoder cannot provide requested pixel format") }
            reader.add(stream)
            guard reader.startReading() else { throw reader.error ?? Failure("Decoder did not start") }
            var next = start
            var lastEnd = start
            while let sample = stream.copyNextSampleBuffer() {
                try autoreleasepool {
                    let time = CMSampleBufferGetPresentationTimeStamp(sample).seconds
                    let sampleDuration = CMSampleBufferGetDuration(sample).seconds
                    let fallbackDuration = sourceFPS > 0 ? 1 / Double(sourceFPS) : 0
                    if time.isFinite {
                        lastEnd = max(lastEnd, time + (sampleDuration.isFinite && sampleDuration > 0 ? sampleDuration : fallbackDuration))
                    }
                    guard time.isFinite, time >= start, time < end, time + 0.000001 >= next else { return }
                    guard let buffer = CMSampleBufferGetImageBuffer(sample) else { throw Failure("Missing image buffer") }
                    try save(CIImage(cvPixelBuffer: buffer).transformed(by: transform), seconds: time)
                    next = start + (floor((time - start) * fps) + 1) / fps
                }
            }
            guard reader.status == .completed else { throw reader.error ?? Failure("Decode incomplete") }
            guard !frames.isEmpty else { throw Failure("Decoder returned no frames") }
            metadata["kind"] = "video"
            metadata["codec"] = codec
            metadata["pixel_format"] = fourCC(pixel)
            metadata["duration"] = assetDuration
            metadata["start"] = start
            metadata["end"] = min(end, lastEnd)
            metadata["nominal_fps"] = sourceFPS
            metadata["format_descriptions"] = descriptions.map { String(describing: $0) }
        }
        metadata["frames"] = frames
        metadata["decode_seconds"] = Date().timeIntervalSince(began)
        try writeJSON(metadata, to: output.appendingPathComponent("manifest.json"))
        print("Decoded \(frames.count) samples from \(source.lastPathComponent)")
    }
}
