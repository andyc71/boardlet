import SwiftUI

struct AccessSettingsSection: View {
    @ObservedObject var access: AccessController
    var body: some View {
        Section {
            Picker("Selection method", selection: $access.settings.mode) {
                ForEach(AccessSettings.Mode.allCases) { mode in Text(mode.title).tag(mode) }
            }.accessibilityIdentifier("selectionMethod")
            if access.settings.mode == .automatic {
                VStack(alignment: .leading) {
                    Text(
                        "Scan interval: \(access.settings.scanInterval, specifier: "%.1f") seconds")
                    Slider(value: $access.settings.scanInterval, in: 0.5...5, step: 0.5) {
                        Text("Scan interval")
                    }
                    .accessibilityIdentifier("scanInterval")
                }
            }
            VStack(alignment: .leading) {
                Text(
                    access.settings.repeatDelay == 0
                        ? "Repeated choices: no delay"
                        : "Repeat delay: \(access.settings.repeatDelay, specifier: "%.1f") seconds")
                Slider(value: $access.settings.repeatDelay, in: 0...2, step: 0.25) {
                    Text("Delay repeated choices")
                }
            }
            VStack(alignment: .leading) {
                Text("Button size: \(access.settings.buttonScale, specifier: "%.1f")×")
                Slider(value: $access.settings.buttonScale, in: 1...2, step: 0.25) {
                    Text("Button size")
                }
            }
        } header: {
            Text("Access")
        } footer: {
            Text(
                "Scanning highlights visible choices in row order, then page navigation (on page sets), Stop, Speak, Undo and Clear. Space starts or selects; Command–Left/Right steps between choices. Selection pauses scanning. Touch remains available. Repeat delay ignores only quick repeats of the same choice. Larger buttons preserve positions and may require scrolling."
            )
        }
        Section("Keyboard and system access") {
            Text(
                "Command–S speaks the message. Command–period stops speech and scanning. Shortcuts pause while a sheet or editor is open. For access to every control, use your device’s Switch Control or Full Keyboard Access settings."
            )
        }
    }
}
