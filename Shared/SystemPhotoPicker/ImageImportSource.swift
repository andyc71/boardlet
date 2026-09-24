import Foundation
import UniformTypeIdentifiers

/// Small provider boundary also used by deterministic importer tests.
/// Test sources never replace the real picker in the UI test suite.
@MainActor
struct ImageImportSource {
    typealias Completion = @Sendable (Result<Data, any Error>) -> Void
    let load: (@escaping Completion) -> Progress

    init(load: @escaping (@escaping Completion) -> Progress) {
        self.load = load
    }

    init(provider: NSItemProvider) {
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
                    completion(.success(data))
                } else {
                    completion(.failure(ImageImportError.empty))
                }
            }
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
