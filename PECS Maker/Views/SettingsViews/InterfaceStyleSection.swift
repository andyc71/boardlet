import SwiftUI

struct InterfaceStyleSection: View {
    @AppStorage(InterfaceStyle.storageKey) private var interfaceStyle = InterfaceStyle.defaultValue

    var body: some View {
        if InterfaceStyle.canChange {
            Section {
                Picker(L10n.InterfaceStyle.title, selection: $interfaceStyle) {
                    Text(L10n.InterfaceStyle.modern).tag(InterfaceStyle.modern)
                    Text(L10n.InterfaceStyle.classic).tag(InterfaceStyle.classic)
                }
                .pickerStyle(.inline)
                .accessibilityIdentifier("Configuration.interfaceStyle")
            } header: {
                Text(L10n.InterfaceStyle.title)
            } footer: {
                Text(L10n.InterfaceStyle.explanation)
            }
        }
    }
}
