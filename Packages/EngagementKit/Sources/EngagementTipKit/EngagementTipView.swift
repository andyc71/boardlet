import SwiftUI
import TipKit
import EngagementCore

/// Optional iOS 17+ inline education. TipKit owns the tip's rules and datastore.
/// Apps configure Tips once and keep their ordinary inline help on iOS 16.
@available(iOS 17.0, *)
public struct EngagementTipView<T: Tip>: View {
    private let tip: T
    @ObservedObject private var coordinator: EngagementCoordinator
    private let context: EngagementContext
    @State private var granted = false
    @State private var eligible = false
    @State private var consumed = false

    public init(_ tip: T, coordinator: EngagementCoordinator, context: EngagementContext) {
        self.tip = tip
        self.coordinator = coordinator
        self.context = context
    }

    public var body: some View {
        Group {
            if granted && context.permitsPresentation && !context.whatsNewPending {
                TipView(tip)
            }
        }
        .task {
            for await shouldDisplay in tip.shouldDisplayUpdates {
                guard !Task.isCancelled else { return }
                eligible = shouldDisplay
            }
        }
        .onChange(of: eligible) { _, shouldDisplay in
            if !shouldDisplay {
                if granted { coordinator.finish(.tip(tip.id)) }
                granted = false
                return
            }
            guard !consumed else { return }
            consumed = true
            granted = coordinator.beginEducation(.tip(tip.id), context: context)
        }
        .onChange(of: context) { _, newContext in
            if !newContext.permitsPresentation || newContext.whatsNewPending {
                consumed = true
                if granted { coordinator.finish(.tip(tip.id)) }
                granted = false
            }
        }
        .onDisappear {
            if granted { coordinator.finish(.tip(tip.id)) }
            granted = false
        }
    }
}
