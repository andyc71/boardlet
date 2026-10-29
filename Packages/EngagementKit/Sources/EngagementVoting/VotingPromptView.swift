import SwiftUI
import EngagementContent
import SharedSwiftUI

/// Inline invitation only; mount votingPresentation once at the scene root.
public struct VotingPromptView: View {
    @EnvironmentObject private var viewModel: FeaturesViewModel
    public init() {}
    public var body: some View {
        if viewModel.showVotingPrompt {
            HStack {
                Button(LocalizedFeatureStrings.invitationTitle, action: viewModel.openVoting)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier(AccessibilityIdentifiersFF.votePromptVoteButton)
                Spacer()
                Button(action: viewModel.dismissPrompt) {
                    Label(LocalizedFeatureStrings.dismissTitle, systemImage: "xmark")
                        .labelStyle(.iconOnly)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityIdentifier(AccessibilityIdentifiersFF.votePromptDismissButton)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.black)
            .padding()
            .background(Color.mfLightYellow, in: RoundedRectangle(cornerRadius: 10))
            .highPriorityGesture(DragGesture(minimumDistance: 20).onEnded { value in
                if value.translation.height < -30 && abs(value.translation.height) > abs(value.translation.width) {
                    viewModel.dismissPrompt()
                }
            })
        }
    }
}
