import SwiftUI
import UniformTypeIdentifiers

/// Local board drags reorder immediately, so the user can see the destination.
struct TopicReorderDropDelegate: DropDelegate {
    static let typeIdentifier = UTType.text.identifier

    let targetID: UUID
    @Binding var draggedTopicID: UUID?
    let repoFactory: PECSRepoFactory

    static func itemProvider(for id: UUID) -> NSItemProvider {
        let provider = NSItemProvider(object: id.uuidString as NSString)
        provider.suggestedName = id.uuidString
        return provider
    }

    func validateDrop(info: DropInfo) -> Bool {
        guard let draggedTopicID else { return false }
        return info.itemProviders(for: [Self.typeIdentifier]).contains {
            $0.suggestedName == draggedTopicID.uuidString
        }
    }

    func dropEntered(info: DropInfo) {
        guard validateDrop(info: info), let source = draggedTopicID else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            _ = repoFactory.moveTopic(id: source, to: targetID)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard validateDrop(info: info) else { return false }
        draggedTopicID = nil
        return true
    }
}
