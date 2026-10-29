import Combine
import Foundation

/// A scan never activates on a timer. Selection always requires an explicit input.
@MainActor
final class AccessController: ObservableObject {
    @Published var settings: AccessSettings {
        didSet {
            stop()
            if let data = try? JSONEncoder().encode(settings.validated) {
                defaults.set(data, forKey: Self.settingsKey)
            }
        }
    }
    @Published private(set) var items: [ScanItem] = []
    @Published private(set) var focusedID: String?
    @Published private(set) var isScanning = false
    @Published private(set) var runID = UUID()
    @Published private(set) var suspensions: Set<String> = []
    private let defaults: UserDefaults
    private var context = ""
    private var lastSelection: (id: String, time: TimeInterval)?
    private static let settingsKey = "communication.access.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        settings =
            defaults.data(forKey: Self.settingsKey)
            .flatMap { try? JSONDecoder().decode(AccessSettings.self, from: $0) }?.validated
            ?? AccessSettings()
    }

    var available: Bool { suspensions.isEmpty }
    var focusedLabel: String? { items.first { $0.id == focusedID }?.label }

    func setItems(_ items: [ScanItem], context: String) {
        guard context != self.context || items != self.items else { return }
        stop()
        self.context = context
        self.items = items
        lastSelection = nil
    }

    func resetForDocument() {
        stop()
        lastSelection = nil
    }

    func suspend(_ reason: String, while value: Bool) {
        if value {
            if suspensions.insert(reason).inserted { stop() }
        } else {
            suspensions.remove(reason)
        }
    }

    func start() {
        guard available, settings.mode != .direct, !items.isEmpty, !isScanning else { return }
        focusedID = items.first?.id
        isScanning = true
        runID = UUID()
    }

    func stop() {
        isScanning = false
        focusedID = nil
        runID = UUID()
    }

    func step(backward: Bool = false) {
        guard available, settings.mode != .direct else { return }
        guard isScanning, let index = items.firstIndex(where: { $0.id == focusedID }) else {
            start()
            return
        }
        focusedID = items[(index + (backward ? items.count - 1 : 1)) % items.count].id
    }

    /// Scoped to ScanControls.task; cancellation, a new run, or a suspension ends the loop.
    func runAutomaticScan() async {
        guard settings.mode == .automatic, isScanning, available else { return }
        let generation = runID
        let interval = settings.validated.scanInterval
        while !Task.isCancelled {
            do { try await Task.sleep(for: .seconds(interval)) } catch { return }
            guard !Task.isCancelled, runID == generation, isScanning, available else { return }
            step()
        }
    }

    /// Space starts a stopped scan; a second press selects and pauses it.
    func select(now: TimeInterval = ProcessInfo.processInfo.systemUptime) -> String? {
        guard available else { return nil }
        guard isScanning, let id = focusedID else {
            start()
            return nil
        }
        guard acceptSelection(id, now: now) else { return nil }
        return id
    }

    /// Also used for direct touch while scanning. Different choices are never delayed.
    func acceptSelection(_ id: String, now: TimeInterval = ProcessInfo.processInfo.systemUptime)
        -> Bool
    {
        guard available else { return false }
        stop()
        let key = context + ":" + id
        if let lastSelection, lastSelection.id == key,
            now - lastSelection.time < settings.validated.repeatDelay
        {
            return false
        }
        lastSelection = (key, now)
        return true
    }
}
