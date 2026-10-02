import Foundation

/// Optional application-owned image service. Provider credentials never enter the app.
struct AISymbolService: Sendable {
    typealias Execute = @Sendable (URLRequest) async throws -> (Data, URLResponse)
    let endpoint: URL
    var execute: Execute = { try await URLSession.shared.data(for: $0) }
    static var configuredEndpoint: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "BoardletAIEndpoint") as? String,
              let url = URL(string: value), url.scheme == "https", url.host != nil else { return nil }
        return url
    }
    func generate(prompt: String) async throws -> Data {
        guard endpoint.scheme == "https", endpoint.host != nil else { throw StorageError.unsafePath }
        var request = URLRequest(url: endpoint); request.httpMethod = "POST"; request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["prompt": prompt])
        let (data, response) = try await execute(request)
        try Task.checkCancellation()
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }
        if http.mimeType?.hasPrefix("image/") == true, !data.isEmpty { return data }
        let result = try JSONDecoder().decode(Response.self, from: data)
        guard let bytes = Data(base64Encoded: result.imageBase64), !bytes.isEmpty else { throw ImageImportError.invalidImage }
        return bytes
    }
    private struct Response: Decodable { let imageBase64: String }
}
