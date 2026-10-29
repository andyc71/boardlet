import SwiftUI

struct GridAdjustmentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var grid: GridOverride
    let source: Data
    let rebuild: (GridOverride) -> Void

    init(source: Data, board: ScannedBoard?, rebuild: @escaping (GridOverride) -> Void) {
        self.source = source
        self.rebuild = rebuild
        var initial = GridOverride()
        if let board, let first = board.cards.first {
            let bounds = board.cards.dropFirst().reduce(first.bounds) { $0.union($1.bounds) }
            initial.rows = board.rows
            initial.columns = board.columns
            initial.left = bounds.minX
            initial.top = bounds.minY
            initial.right = max(0, 1 - bounds.maxX)
            initial.bottom = max(0, 1 - bounds.maxY)
        }
        _grid = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DetectionPreview(source: source, cells: grid.cells, pictures: [])
                    Text("Align the blue grid with the cards. Exclude status bars, headings and margins. Rebuilding replaces current card edits.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Grid") {
                    Stepper("Rows: \(grid.rows)", value: $grid.rows, in: 1...12)
                    Stepper("Columns: \(grid.columns)", value: $grid.columns, in: 1...12)
                    Text("Cell inset: \(grid.inset, format: .percent.precision(.fractionLength(0)))")
                    Slider(value: $grid.inset, in: 0...0.15).accessibilityLabel("Cell inset")
                }
                Section("Board margins") {
                    CropControls(left: $grid.left, top: $grid.top, right: $grid.right, bottom: $grid.bottom)
                }
            }
            .navigationTitle("Adjust grid").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Rebuild") { rebuild(grid); dismiss() }
                }
            }
        }
    }
}
