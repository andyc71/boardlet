import SwiftUI

struct PrintOptionsView: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dismiss) private var dismiss
    let boardID: UUID
    func binding<T>(_ path: WritableKeyPath<PrintSettings, T>, fallback: T) -> Binding<T> {
        Binding(get: { store.board(boardID)?.print[keyPath: path] ?? fallback }, set: { value in store.edit(boardID) { $0.print[keyPath: path] = value } })
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("Paper") {
                    Picker("Paper size", selection: binding(\.paper, fallback: .a4)) { ForEach(Paper.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                    Toggle("Landscape", isOn: binding(\.landscape, fallback: false))
                    Text("Paper orientation stays the same when you rotate your device.").font(.footnote).foregroundStyle(.secondary)
                }
                Section("Grid") {
                    Stepper("\(store.board(boardID)?.print.columns ?? 2) across", value: binding(\.columns, fallback: 2), in: 1...12)
                    Stepper("\(store.board(boardID)?.print.rows ?? 3) rows", value: binding(\.rows, fallback: 3), in: 1...12)
                    Toggle("Repeat a single card to fill the page", isOn: binding(\.repeatSingle, fallback: false))
                    Text("Picture margins")
                    Slider(value: binding(\.marginFraction, fallback: 0.05), in: 0...0.2)
                    Stepper("Border: \(Int(store.board(boardID)?.print.borderWidth ?? 1)) pt", value: binding(\.borderWidth, fallback: 1), in: 0...8)
                }
                Section("Labels") {
                    Toggle("Show labels", isOn: binding(\.showLabels, fallback: true))
                    Toggle("Labels above pictures", isOn: binding(\.labelsAbove, fallback: false))
                    Toggle("Bold labels", isOn: binding(\.labelBold, fallback: true))
                    Text("Label size"); Slider(value: binding(\.labelFraction, fallback: 0.18), in: 0.08...0.4)
                }
                Section("Board title") {
                    Toggle("Show board title", isOn: binding(\.showTitle, fallback: true))
                    Toggle("Bold board title", isOn: binding(\.titleBold, fallback: true))
                    Text("Title size"); Slider(value: binding(\.titleFraction, fallback: 0.06), in: 0.03...0.2)
                }
                Section("Style") {
                    ColorChoice(title: "Background", selection: binding(\.background, fallback: "#FFFFFF"))
                    ColorChoice(title: "Text colour", selection: binding(\.labelColor, fallback: "#182435"))
                    ColorChoice(title: "Border colour", selection: binding(\.borderColor, fallback: "#CCD3DB"))
                    ColorChoice(title: "Title colour", selection: binding(\.titleColor, fallback: "#182435"))
                    Toggle("Fitzgerald category borders", isOn: binding(\.categoryBorders, fallback: false))
                }
            }.navigationTitle("Paper and layout").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

struct ColorChoice: View {
    let title: LocalizedStringKey
    @Binding var selection: String
    var body: some View {
        ColorPicker(title, selection: Binding(get: { Color(uiColor: UIColor(hex: selection)) }, set: { color in
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
            selection = String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        }), supportsOpacity: false)
    }
}
