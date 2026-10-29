import Foundation

struct CommunicationToken: Identifiable, Equatable {
    let id = UUID()
    var text: String
    let imagePNG: Data?
}
