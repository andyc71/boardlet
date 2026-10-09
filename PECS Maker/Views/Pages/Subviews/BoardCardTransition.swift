import SwiftUI

extension View {
    @ViewBuilder
    func boardCardTransitionSource(id: String, namespace: Namespace.ID?) -> some View {
        if #available(iOS 18.0, *), let namespace {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    @ViewBuilder
    func boardCardZoomTransition(sourceID: String?, namespace: Namespace.ID, reduceMotion: Bool) -> some View {
        if #available(iOS 18.0, *), let sourceID, !reduceMotion {
            navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            self
        }
    }
}
