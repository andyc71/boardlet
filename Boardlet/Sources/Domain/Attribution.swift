import Foundation

struct Attribution: Codable, Equatable, Sendable {
    var provider: String
    var symbolID: String?
    var credit: String
    var license: String?
    var url: String?
    var modified = false

    static func arasaac(_ id: Int) -> Attribution {
        Attribution(provider: "ARASAAC", symbolID: String(id),
                    credit: "Pictograms: Sergio Palao / ARASAAC, Government of Aragón",
                    license: "CC BY-NC-SA", url: "https://arasaac.org", modified: false)
    }
    var exportCredit: String {
        [credit, license, url, modified ? "Modified / Modificado" : nil].compactMap { $0 }.joined(separator: " · ")
    }
}
