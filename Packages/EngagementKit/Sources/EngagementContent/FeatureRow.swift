//
//  FeatureRow.swift
//
//
//  Created by Andy on 24/05/2024.
//

import SwiftUI
import SharedSwiftUI

public struct FeatureRow<TViewModel: FeaturesViewModelProtocol> : View {
    @State private var didVote: Bool = false
        
    var feature: Feature
    var viewModel: TViewModel
    
    var imageSize: CGFloat = 40
    public init(feature: Feature, viewModel: TViewModel, imageSize: CGFloat = 40) {
        self.feature = feature
        self.viewModel = viewModel
        self.imageSize = imageSize
    }
    
    func makeIcon() -> some View {
        ZStack(alignment: .center) {
            if feature.sendMail == true {
                Image(systemName: "envelope")
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageSize, height: imageSize)
            }
            else {
                let iconName = feature.systemIcon ?? "hand.thumbsup"
                if didVote {
                    Image(systemName: "\(iconName).fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: imageSize, height: imageSize)
                }
                else {
                    Image(systemName: iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: imageSize, height: imageSize)
                }

                //Text("Vote", bundle: .module)
            }
        }
        .width(imageSize)
        .foregroundStyle(Color.mfVeryBrightBlue)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifiersFF.FeaturesView.featureCell(id: feature.id))
        //.padding(.vertical, 8)
        .if(viewModel.canVote) { icon in
            Button {
                withAnimation { didVote = true }
                viewModel.handleVote(for: feature)
            } label: {
                icon.frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(feature.name)
            .accessibilityIdentifier(AccessibilityIdentifiersFF.FeaturesView.featureCell(id: feature.id))
        }
    }
    
    public var body: some View {
        HStack(alignment: viewModel.canVote ? .center : .top, spacing: imageSize == 32 ? 12 : 20) {
            if viewModel.iconPosition == .leading {
                makeIcon()
            }
            VStack(alignment: .leading) {
                Text(feature.name)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    //Need this because when we use AutoPresentationHeightModifier
                    //to calculate the height we will end up with enough room for
                    //one line of text if we don't have it.
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(AccessibilityIdentifiersFF.FeaturesView.featureTitle)
                
                Text(feature.description)
                    .font(.subheadline)
                    //.foregroundStyle(.secondary)
                    .foregroundStyle(Color.mfOpal)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(AccessibilityIdentifiersFF.FeaturesView.featureDescription)
            }
            if viewModel.iconPosition == .trailing {
                Spacer()
                makeIcon()
            }
            else {
                //This spacer is just there so that if the Image + Text is smaller on
                //this row than any other rows some padding is added to prevent this
                //row from being center aligned.
                Spacer(minLength: 0)
            }
        }

    }
}


extension VerticalAlignment {
    private struct LeadingAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.leading]
        }
    }

    /// A guide for aligning titles.
    static let leadingAlignmentGuide = VerticalAlignment(
        LeadingAlignment.self
    )
}

