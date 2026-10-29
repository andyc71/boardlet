import SwiftUI

extension Color {
    init(snapARGB value: UInt32) {
        self.init(.sRGB,
                  red: Double((value >> 16) & 255) / 255,
                  green: Double((value >> 8) & 255) / 255,
                  blue: Double(value & 255) / 255,
                  opacity: Double((value >> 24) & 255) / 255)
    }
}
