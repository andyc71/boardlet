import SwiftUI

struct WelcomeView: View {
    var source: Data?
    @Binding var showGrid: Bool
    var create: () -> Void
    var sample: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let source {
                    DetectionPreview(source: source, cells: [], pictures: []).frame(maxHeight: 300)
                    Text("Set the grid to continue").font(.title2.bold())
                    Button("Adjust grid") { showGrid = true }.buttonStyle(.borderedProminent)
                } else {
                    Image(systemName: "square.grid.3x3.square").font(.largeTitle).foregroundStyle(.indigo)
                        .accessibilityHidden(true)
                    Text("Your words.\nYour choice board.").font(.largeTitle.bold()).multilineTextAlignment(.center)
                    Text("Import a screenshot to separate its pictures and labels into editable cards. Choose Files to import a TD Snap page set (.sps) with all its pages and links.")
                        .foregroundStyle(.secondary).multilineTextAlignment(.center)
                    VStack(alignment: .leading, spacing: 18) {
                        Label("Find the card grid", systemImage: "viewfinder")
                        Label("Read and separate the labels", systemImage: "text.viewfinder")
                        Label("Review, save and use your board", systemImage: "checkmark.square")
                    }.padding().frame(maxWidth: .infinity, alignment: .leading)
                        .background(.background, in: RoundedRectangle(cornerRadius: 18))
                    Button("Create a board", action: create).buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("newBoard")
                    Button("Try a sample board", action: sample).buttonStyle(.bordered)
                        .accessibilityIdentifier("sampleBoard")
                    Text("Best with straight screenshots and a regular grid. Nothing is uploaded. Your boards and edits save automatically in the Board library.")
                        .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
            }.padding(28).frame(maxWidth: 560).frame(maxWidth: .infinity)
        }
    }
}
