import SwiftUI

struct StartupWhatsNewView: View {
    let notes: ReleaseNotes
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.largeTitle)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                Text(notes.title.trimmingCharacters(in: .whitespaces))
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("FeaturesView.title")
                if let header = notes.header {
                    Text(header).font(.title3).foregroundStyle(.secondary)
                }
                ForEach(notes.features) { feature in
                    HStack(alignment: .top, spacing: 18) {
                        Image(systemName: feature.systemIcon)
                            .font(.title2)
                            .foregroundStyle(.tint)
                            .frame(width: 32)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 7) {
                            Text(feature.name).font(.headline)
                            Text(feature.description).foregroundStyle(.secondary)
                        }
                    }
                }
                if let footer = notes.footer {
                    Text(footer).font(.footnote).foregroundStyle(.secondary)
                }
                Button(action: onContinue) {
                    Text(notes.buttonTitle).font(.headline).frame(maxWidth: .infinity).padding(10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("FeaturesView.closeButton")
            }
            .padding(28)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .tint(Color("mfBoardActionBlue"))
    }
}
