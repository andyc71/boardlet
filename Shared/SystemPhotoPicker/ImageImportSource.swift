import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Small provider boundary also used by deterministic importer tests.
/// Test sources never replace the real picker in the UI test suite.
@MainActor
struct ImageImportSource {
    nonisolated static let maximumPixelDimension = 2_560

    typealias Completion = @Sendable (Result<Data, any Error>) -> Void
    let load: (@escaping Completion) -> Progress

    init(load: @escaping (@escaping Completion) -> Progress) {
        self.load = load
    }

    init(provider: NSItemProvider, maximumPixelDimension: Int = Self.maximumPixelDimension) {
        load = { completion in
            guard let type = provider.registeredTypeIdentifiers.first(where: {
                UTType($0)?.conforms(to: .image) == true
            }) else {
                completion(.failure(ImageImportError.unsupported))
                return Progress(totalUnitCount: 0)
            }
            return provider.loadDataRepresentation(forTypeIdentifier: type) { data, error in
                if let error {
                    completion(.failure(error))
                } else if let data {
                    // Provider callbacks can arrive on any queue. Use a dedicated queue so
                    // image decoding and PNG encoding never block the main actor.
                    DispatchQueue.global(qos: .userInitiated).async {
                        guard let prepared = Self.preparePNG(
                            from: data,
                            maximumPixelDimension: maximumPixelDimension
                        ) else {
                            completion(.failure(ImageImportError.invalidImage))
                            return
                        }
                        completion(.success(prepared))
                    }
                } else {
                    completion(.failure(ImageImportError.empty))
                }
            }
        }
    }

    nonisolated private static func preparePNG(
        from data: Data,
        maximumPixelDimension: Int
    ) -> Data? {
        autoreleasepool {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: max(1, maximumPixelDimension),
                kCGImageSourceShouldCacheImmediately: true
            ]
            guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                return nil
            }

            let output = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                output,
                UTType.png.identifier as CFString,
                1,
                nil
            ) else { return nil }
            CGImageDestinationAddImage(destination, thumbnail, nil)
            guard CGImageDestinationFinalize(destination) else { return nil }
            return output as Data
        }
    }
}

enum ImageImportError: LocalizedError {
    case unsupported, empty, invalidImage

    var errorDescription: String? {
        switch self {
        case .unsupported: return "The selected item has no supported image representation."
        case .empty: return "The photo provider returned no data."
        case .invalidImage: return "The selected image could not be decoded."
        }
    }
}
