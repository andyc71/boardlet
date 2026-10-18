import AISymbols
import Foundation
import OpenAIKit

/// Adapts the app's existing image client to the symbol picker's service interface.
actor OpenAISymbolService: AISymbolGenerating {
    private let client: OpenAI

    init(config: OpenAIKit.Configuration) {
        client = OpenAI(config)
    }

    func generateImageData(for prompt: String) async throws -> Data {
        let parameters = ImageParameters(
            prompt: prompt,
            resolution: .medium,
            responseFormat: .base64Json
        )
        let response = try await client.createImage(parameters: parameters)
        guard let image = response.data.first,
              let data = Data(base64Encoded: image.image), !data.isEmpty else {
            throw AISymbolGenerationError.emptyImageData
        }
        return data
    }
}
