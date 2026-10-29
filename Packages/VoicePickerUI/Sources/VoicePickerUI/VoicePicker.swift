import SwiftUI
import AVFoundation

enum ChoiceBoardVoicePreference {
    static let storageKey = "choiceBoardVoiceIdentifier"
    static let localeStorageKey = "choiceBoardVoiceLocale"

    static func normalizedLocale(_ identifier: String) -> String {
        identifier.replacingOccurrences(of: "_", with: "-")
    }

    static func languageCode(for locale: String) -> String {
        normalizedLocale(locale).split(separator: "-").first.map(String.init) ?? locale
    }
}

private struct VoiceLocaleGroup: Identifiable {
    let locale: String
    let voices: [AVSpeechSynthesisVoice]

    var id: String { locale }
}

private enum PersonalVoiceAccess {
    case notDetermined
    case authorized
    case denied
    case unsupported

    static var current: Self {
        guard #available(iOS 17.0, *) else { return .unsupported }
        switch AVSpeechSynthesizer.personalVoiceAuthorizationStatus {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .denied: return .denied
        case .unsupported: return .unsupported
        @unknown default: return .unsupported
        }
    }
}

public struct VoicePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.scenePhase) private var scenePhase
    @Binding private var selectedVoiceIdentifier: String
    @Binding private var selectedVoiceLocale: String
    private let defaultVoice: (String) -> AVSpeechSynthesisVoice?
    private let previewVoice: (AVSpeechSynthesisVoice) -> Void
    private let stopPreview: () -> Void

    public init(voiceIdentifier: Binding<String>, voiceLocale: Binding<String>,
                defaultVoice: @escaping (String) -> AVSpeechSynthesisVoice?,
                preview: @escaping (AVSpeechSynthesisVoice) -> Void,
                stopPreview: @escaping () -> Void) {
        _selectedVoiceIdentifier = voiceIdentifier
        _selectedVoiceLocale = voiceLocale
        self.defaultVoice = defaultVoice
        previewVoice = preview
        self.stopPreview = stopPreview
    }
    @State private var showMoreVoicesHelp = false
    @State private var showPersonalVoiceHelp = false
    @State private var personalVoiceAccess = PersonalVoiceAccess.current
    @State private var voices = AVSpeechSynthesisVoice.speechVoices()

    private func refreshVoices() {
        personalVoiceAccess = PersonalVoiceAccess.current
        voices = AVSpeechSynthesisVoice.speechVoices()
        if !selectedVoiceIdentifier.isEmpty,
           !voices.contains(where: { $0.identifier == selectedVoiceIdentifier }) {
            selectedVoiceIdentifier = ""
        }
    }

    private func requestPersonalVoiceAccess() {
        guard #available(iOS 17.0, *) else { return }
        Task { @MainActor in
            _ = await AVSpeechSynthesizer.requestPersonalVoiceAuthorization()
            refreshVoices()
        }
    }

    private func preview(_ voice: AVSpeechSynthesisVoice?) {
        guard let voice else { return }
        stopPreview()
        previewVoice(voice)
    }

    private var appVoiceLocale: String {
        ChoiceBoardVoicePreference.normalizedLocale(locale.identifier)
    }

    private var activeVoiceLocale: String {
        selectedVoiceLocale.isEmpty ? appVoiceLocale : selectedVoiceLocale
    }

    private var availableLocales: [String] {
        Set(voices.map(\.language)).sorted {
            localeName($0).localizedStandardCompare(localeName($1)) == .orderedAscending
        }
    }

    private var premiumVoices: [AVSpeechSynthesisVoice] {
        let language = ChoiceBoardVoicePreference.languageCode(for: activeVoiceLocale)
        return voices.filter {
            $0.quality == .premium
                && ChoiceBoardVoicePreference.languageCode(for: $0.language) == language
                && !isPersonalVoice($0)
        }
        .sorted {
            let firstRank = $0.language == activeVoiceLocale ? 0 : 1
            let secondRank = $1.language == activeVoiceLocale ? 0 : 1
            if firstRank != secondRank { return firstRank < secondRank }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private var allPersonalVoices: [AVSpeechSynthesisVoice] {
        voices.filter(isPersonalVoice)
    }

    private var personalVoices: [AVSpeechSynthesisVoice] {
        let language = ChoiceBoardVoicePreference.languageCode(for: activeVoiceLocale)
        return allPersonalVoices
            .filter { ChoiceBoardVoicePreference.languageCode(for: $0.language) == language }
            .sorted {
                let firstRank = $0.language == activeVoiceLocale ? 0 : 1
                let secondRank = $1.language == activeVoiceLocale ? 0 : 1
                if firstRank != secondRank { return firstRank < secondRank }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
    }

    private var effectiveVoice: AVSpeechSynthesisVoice? {
        if let selected = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier) {
            return selected
        }
        return defaultVoice(activeVoiceLocale)
    }

    private var qualityNotice: String {
        guard let voice = effectiveVoice else {
            return VoiceStrings.noPremiumVoiceNotice
        }
        if isPersonalVoice(voice) {
            return VoiceStrings.personalVoiceSelectedNotice
        }
        if voice.quality == .premium {
            return VoiceStrings.premiumVoiceNotice
        }
        if voice.quality == .enhanced {
            return VoiceStrings.enhancedVoiceNotice
        }
        return VoiceStrings.standardVoiceNotice
    }

    private func isPersonalVoice(_ voice: AVSpeechSynthesisVoice) -> Bool {
        if #available(iOS 17.0, *) {
            return voice.voiceTraits.contains(.isPersonalVoice)
        }
        return false
    }

    private var voiceGroups: [VoiceLocaleGroup] {
        let language = ChoiceBoardVoicePreference.languageCode(for: activeVoiceLocale)
        let matchingVoices = voices.filter {
            ChoiceBoardVoicePreference.languageCode(for: $0.language) == language
                && !isPersonalVoice($0)
        }
        let recommendedLocale = defaultVoice(activeVoiceLocale)?.language
        return Dictionary(grouping: matchingVoices, by: \.language)
            .map { VoiceLocaleGroup(locale: $0.key, voices: $0.value.sorted { $0.name < $1.name }) }
            .sorted {
                let firstRank = $0.locale == activeVoiceLocale ? 0 : ($0.locale == recommendedLocale ? 1 : 2)
                let secondRank = $1.locale == activeVoiceLocale ? 0 : ($1.locale == recommendedLocale ? 1 : 2)
                if firstRank != secondRank { return firstRank < secondRank }
                return localeName($0.locale).localizedStandardCompare(localeName($1.locale)) == .orderedAscending
            }
    }

    private var localeSelection: Binding<String> {
        Binding(get: { selectedVoiceLocale }, set: { newLocale in
            selectedVoiceLocale = newLocale
            selectedVoiceIdentifier = ""
        })
    }

    private func localeName(_ identifier: String) -> String {
        locale.localizedString(forIdentifier: identifier) ?? identifier
    }

    private func voiceRow(_ voice: AVSpeechSynthesisVoice, isRecommendation: Bool = false,
                          isPersonal: Bool = false) -> some View {
        HStack {
            Button {
                selectedVoiceLocale = voice.language
                selectedVoiceIdentifier = voice.identifier
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(voice.name)
                        if isRecommendation || isPersonal {
                            Text("\(localeName(voice.language)) (\(voice.language))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if selectedVoiceIdentifier == voice.identifier {
                        Image(systemName: "checkmark")
                    }
                }
            }
            .accessibilityIdentifier("VoicePicker.\(isPersonal ? "personalVoice" : (isRecommendation ? "recommendedVoice" : "voice")).\(voice.identifier)")
            .accessibilityAddTraits(selectedVoiceIdentifier == voice.identifier ? .isSelected : [])

            Button {
                preview(voice)
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
            }
            .accessibilityLabel(VoiceStrings.previewVoice(voice.name))
            .accessibilityIdentifier("VoicePicker.\(isPersonal ? "personalPreview" : (isRecommendation ? "recommendedPreview" : "preview")).\(voice.identifier)")
        }
        .buttonStyle(.borderless)
    }

    private func personalVoiceHelpButton(_ title: String) -> some View {
        Button(title) {
            showPersonalVoiceHelp = true
        }
        .accessibilityIdentifier("MainMenu.personalVoiceHelpButton")
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(VoiceStrings.voiceLanguage, selection: localeSelection) {
                        Text("\(VoiceStrings.appLanguage) (\(localeName(appVoiceLocale)))")
                            .tag("")
                        ForEach(availableLocales, id: \.self) { voiceLocale in
                            Text("\(localeName(voiceLocale)) (\(voiceLocale))")
                                .tag(voiceLocale)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("MainMenu.voiceLanguagePicker")
                }

                Section {
                    HStack {
                        Button {
                            selectedVoiceIdentifier = ""
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(VoiceStrings.defaultVoice)
                                    if let recommendedVoice = defaultVoice(activeVoiceLocale) {
                                        Text(recommendedVoice.name)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if selectedVoiceIdentifier.isEmpty {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .accessibilityIdentifier("MainMenu.defaultVoiceButton")
                        .accessibilityAddTraits(selectedVoiceIdentifier.isEmpty ? .isSelected : [])

                        Button {
                            preview(defaultVoice(activeVoiceLocale))
                        } label: {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                        }
                        .accessibilityLabel(VoiceStrings.previewVoice(VoiceStrings.defaultVoice))
                        .accessibilityIdentifier("MainMenu.defaultVoicePreviewButton")
                    }
                    .buttonStyle(.borderless)
                }

                if premiumVoices.isEmpty {
                    Section {
                        Text(qualityNotice)
                            .accessibilityIdentifier("MainMenu.voiceQualityNotice")
                        Button(VoiceStrings.getMoreVoices) {
                            showMoreVoicesHelp = true
                        }
                    }
                } else {
                    Section(VoiceStrings.premiumVoices) {
                        ForEach(premiumVoices, id: \.identifier) { voice in
                            voiceRow(voice, isRecommendation: true)
                        }
                    }
                }

                if #available(iOS 17.0, *) {
                    Section(VoiceStrings.personalVoice) {
                        switch personalVoiceAccess {
                        case .notDetermined:
                            Text(VoiceStrings.personalVoiceAccessExplanation)
                            Button(VoiceStrings.allowPersonalVoice) {
                                requestPersonalVoiceAccess()
                            }
                            .accessibilityIdentifier("MainMenu.personalVoiceAccessButton")
                            personalVoiceHelpButton(VoiceStrings.createPersonalVoice)
                        case .authorized:
                            if personalVoices.isEmpty {
                                Text(allPersonalVoices.isEmpty
                                     ? VoiceStrings.noPersonalVoices
                                     : VoiceStrings.noPersonalVoiceForLanguage)
                                if allPersonalVoices.isEmpty {
                                    personalVoiceHelpButton(VoiceStrings.createPersonalVoice)
                                }
                            } else {
                                ForEach(personalVoices, id: \.identifier) { voice in
                                    voiceRow(voice, isPersonal: true)
                                }
                            }
                        case .denied:
                            Text(VoiceStrings.personalVoiceAccessDenied)
                            personalVoiceHelpButton(VoiceStrings.personalVoiceSettingsHelp)
                        case .unsupported:
                            Text(VoiceStrings.personalVoiceUnsupported)
                        }
                    }
                    .alert(VoiceStrings.personalVoice, isPresented: $showPersonalVoiceHelp) {
                        Button(VoiceStrings.doneButton, role: .cancel) { }
                    } message: {
                        Text(VoiceStrings.personalVoiceHelp)
                    }
                }

                ForEach(voiceGroups) { group in
                    Section {
                        ForEach(group.voices, id: \.identifier) { voice in
                            voiceRow(voice)
                        }
                    } header: {
                        Text("\(localeName(group.locale)) (\(group.locale))")
                    }
                }

            }
            .navigationTitle(VoiceStrings.changeVoiceButton)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(VoiceStrings.doneButton) { dismiss() }
                }
            }
            .onAppear {
                refreshVoices()
                if selectedVoiceLocale.isEmpty,
                   let voice = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier),
                   ChoiceBoardVoicePreference.languageCode(for: voice.language)
                    != ChoiceBoardVoicePreference.languageCode(for: appVoiceLocale) {
                    selectedVoiceLocale = voice.language
                }
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    refreshVoices()
                }
            }
            .onDisappear {
                stopPreview()
            }
            .sheet(isPresented: $showMoreVoicesHelp) {
                MoreVoicesHelpSheet()
            }
        }
    }
}

private struct MoreVoicesHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    private var appDisplayName: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? Bundle.main.bundleURL.deletingPathExtension().lastPathComponent
    }

    private var voicesPath: String {
        if #available(iOS 26.0, *) {
            return VoiceStrings.moreVoicesPathModern
        }
        return VoiceStrings.moreVoicesPathLegacy
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 44))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .blue)
                        .frame(width: 60, height: 60)
                        .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 18))
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(VoiceStrings.moreVoicesTitle)
                        .font(.title.bold())
                        .accessibilityIdentifier("MainMenu.moreVoicesHelpTitle")
                    Text(VoiceStrings.moreVoicesIntro)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 10) {
                    MoreVoicesHelpStep(number: 1,
                                       title: VoiceStrings.moreVoicesStepOneTitle,
                                       detail: VoiceStrings.moreVoicesStepOneDetail)
                    MoreVoicesHelpStep(number: 2,
                                       title: VoiceStrings.moreVoicesStepTwoTitle,
                                       detail: voicesPath,
                                       highlightsDetail: true)
                    MoreVoicesHelpStep(number: 3,
                                       title: VoiceStrings.moreVoicesStepThreeTitle,
                                       detail: VoiceStrings.moreVoicesStepThreeDetail)
                }

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(VoiceStrings.moreVoicesReturnTitle(appDisplayName))
                            .font(.headline)
                        Text(VoiceStrings.moreVoicesReturnDetail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.09), in: RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .safeAreaInset(edge: .bottom) {
            Button { dismiss() } label: {
                Text(VoiceStrings.moreVoicesGotIt)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 15))
            }
                .buttonStyle(.plain)
                .accessibilityIdentifier("MainMenu.moreVoicesHelpDoneButton")
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(.regularMaterial)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

private struct MoreVoicesHelpStep: View {
    let number: Int
    let title: String
    let detail: String
    var highlightsDetail = false

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(.blue, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(highlightsDetail ? .subheadline.weight(.semibold) : .subheadline)
                    .foregroundStyle(highlightsDetail ? Color.primary : Color.secondary)
                    .accessibilityIdentifier(highlightsDetail
                                             ? "MainMenu.moreVoicesHelpPath"
                                             : "MoreVoicesHelp.step\(number)Detail")
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .contain)
    }
}

