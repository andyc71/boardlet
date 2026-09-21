//
//  AIImageGenerationService.swift
//  PECS Maker
//

import Foundation

/// A backend boundary for AI image generation. Provider credentials must stay
/// on the server and are never accepted by this client API.
protocol AIImageGenerating: Sendable {
    var isConfigured: Bool { get }

    func generateImage(prompt: String) async throws -> Data
}

enum AIImageGenerationError: Error, Equatable, LocalizedError, Sendable {
    case invalidConfiguration
    case invalidResponse
    case requestFailed(statusCode: Int)
    case invalidImageData
    case unavailable

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            "The secure AI image service is not configured correctly."
        case .invalidResponse:
            "The secure AI image service returned an invalid response."
        case .requestFailed(let statusCode):
            "The secure AI image service failed with status code \(statusCode)."
        case .invalidImageData:
            "The secure AI image service returned invalid image data."
        case .unavailable:
            "AI image generation is unavailable."
        }
    }
}

struct AIImageServiceConfiguration: Equatable, Sendable {
    static let endpointInfoKey = "AI_IMAGE_SERVICE_URL"

    let endpoint: URL

    init?(infoDictionary: [String: Any]) {
        guard
            let value = infoDictionary[Self.endpointInfoKey] as? String,
            let endpoint = URL(string: value),
            endpoint.scheme?.lowercased() == "https"
        else {
            return nil
        }

        self.endpoint = endpoint
    }
}

actor BackendAIImageGenerationService: AIImageGenerating {
    nonisolated let isConfigured = true

    private let configuration: AIImageServiceConfiguration
    private let session: URLSession

    init(
        configuration: AIImageServiceConfiguration,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session
    }

    func generateImage(prompt: String) async throws -> Data {
        try Task.checkCancellation()

        var request = URLRequest(url: configuration.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(Request(prompt: prompt))

        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()

        guard let response = response as? HTTPURLResponse else {
            throw AIImageGenerationError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw AIImageGenerationError.requestFailed(statusCode: response.statusCode)
        }

        let payload = try JSONDecoder().decode(Response.self, from: data)
        guard let imageData = Data(base64Encoded: payload.imageBase64) else {
            throw AIImageGenerationError.invalidImageData
        }
        return imageData
    }
}

actor UnavailableAIImageGenerationService: AIImageGenerating {
    nonisolated let isConfigured = false

    func generateImage(prompt: String) async throws -> Data {
        throw AIImageGenerationError.unavailable
    }
}

enum AIImageGenerationServices {
    static func makeDefault(
        infoDictionary: [String: Any] = Bundle.main.infoDictionary ?? [:]
    ) -> any AIImageGenerating {
        guard let configuration = AIImageServiceConfiguration(infoDictionary: infoDictionary) else {
            return UnavailableAIImageGenerationService()
        }
        return BackendAIImageGenerationService(configuration: configuration)
    }
}

private struct Request: Codable, Sendable {
    let prompt: String
}

private struct Response: Codable, Sendable {
    let imageBase64: String
}
