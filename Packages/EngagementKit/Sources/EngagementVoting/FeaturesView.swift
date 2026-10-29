//
//  FeaturesView.swift
//  FeaturePickerTest
//
//  Created by Andy on 23/05/2024.
//

import SwiftUI
import EngagementContent
import SharedSwiftUI
import MailFramework

struct FeaturesView<TViewModel: FeaturesViewModelProtocol>: View {
    @ObservedObject var viewModel: TViewModel
    @EnvironmentObject var currentTheme: SharedUITheme

    @ViewBuilder
    var body: some View {
        Group {
            //VStack(spacing: MFPopoverView.internalPaddingV) {

            VStack(spacing: 0) {

                //Spacer()

                //Text("Vote for New Features", bundle: .module)
                Text(viewModel.title)
                    //.font(.largeTitle)
                    .font(currentTheme.headerStyle.largeFont)
                    .foregroundStyle(Color(currentTheme.headerStyle.textColor))
                    .multilineTextAlignment(.center)
                    //.lineSpacing(currentTheme.headerStyle.largeFontSize * 0.02)
                    .lineSpacing(0)
                    .accessibilityIdentifier(AccessibilityIdentifiersFF.FeaturesView.title)
                    .padding(.top, .extraLarge)
                    .padding(.horizontal, .regular)
                    //.padding(.extraLarge)
                    .padding(.bottom, viewModel.header != nil ? .regular : .extraLarge)


                    if let header = viewModel.header {
                            Text(header)
                                //.font(.headline)
                                .font(currentTheme.headerStyle.smallerFont)
                                .foregroundStyle(Color.mfOpal)
                                .listRowBackground(Color.clear)
                                //.multilineTextAlignment(.center)
                                //.frame(alignment: .center)
                                //.multilineTextAlignment(.leading)
                                //.frame(alignment: .leading)
                                //.padding(.bottom, .large)
                                .padding(.horizontal, .regular)
                                .padding(.bottom, .large)
                                .accessibilityIdentifier(AccessibilityIdentifiersFF.FeaturesView.header)
                            //Spacer()
                        //.listRowSeparatorHiddenIfAvailable()

                    }

                    //Section {
                        ForEach(viewModel.features, id: \.id) { feature in
                            FeatureRow(feature: feature, viewModel: viewModel)
                                //.padding(.bottom, MFPopoverView.internalPaddingV)
                                //.padding(.bottom, .large)
                                .padding(.regular)
    //                        if !viewModel.isLastFeature(feature) {
    //                            Divider()
    //                        }
                        }
                    //}

                    if let footer = viewModel.footer {
                        Text(footer)
                            .font(.callout)
                            //.foregroundStyle(.secondaryLabel)
                            .foregroundStyle(Color.mfOpal)
                            .listRowBackground(Color.clear)
                            .listRowSeparatorHiddenIfAvailable()
                            .multilineTextAlignment(.center)
                            .frame(alignment: .center)
                            //.padding(.top, MFPopoverView.internalPaddingV)
                            //.padding(.bottom, .large)
                            .padding(.top, .large)
                            .padding(.horizontal, .regular)
                            //.padding(.vertical, .extraLarge)
                            .padding(.bottom, .extraLarge)
                            .accessibilityIdentifier(AccessibilityIdentifiersFF.FeaturesView.footer)
                    }


                //}
                //.listStyle(.plain)
                //.listSectionSpacingCompactIfAvailable()
                //.maxHeight(500)
                //Spacer()

    //            HeaderButton.closeButton(isForNativeToolbar: false, closeAction: {
    //                viewModel.dismissFeaturesView()
    //            })
                CapsuleButton(viewModel.buttonTitle, role: viewModel.canVote ? .secondary : .primary) {
                    viewModel.dismissFeaturesView()
                }
                .accessibilityIdentifier(AccessibilityIdentifiersFF.FeaturesView.closeButton)
                //.padding(.large)
                .padding(.horizontal, .extraLarge)
                //.padding(.bottom, .regular)
                .padding(.bottom, .extraLarge)


            }
            //.padding(.horizontal, MFPopoverView.internalPaddingH)
            //.padding(.vertical, MFPopoverView.internalPaddingV)
            //.padding(.regular)
            //.frame(minWidth: 200, idealWidth: 300, maxWidth: 300)
            .background(Color(UIColor.mfAlertBackground))
            //.backgroundIgnoresSafeAreaIfAvailable()
            .backgroundWithSafeAreaIfAvailable(Color(UIColor.mfAlertBackground))
            //.ignoresSafeArea(edges: .bottom)
            //.background(ignoresSafeAreaEdges: .bottom)

            //.roundedBackgroundStyle(backgroundColor: .systemBackground, borderColor: .systemBackground)
            //.shadow(radius: 20)

        }
    }

}

extension View {
    @ViewBuilder
    func backgroundIgnoresSafeAreaIfAvailable() -> some View {
        if #available(iOS 15.0, *) {
            self.background(ignoresSafeAreaEdges: .all)
        } else {
            self
        }
    }
    @ViewBuilder
    func backgroundWithSafeAreaIfAvailable<S>(_ style: S) -> some View where S : ShapeStyle {
        if #available(iOS 15.0, *) {
            self.background(style, ignoresSafeAreaEdges: .all)
        } else {
            self
        }
    }
}

extension View {
    @ViewBuilder
    func listRowSeparatorHiddenIfAvailable() -> some View {
        if #available(iOS 15.0, *) {
            self.listRowSeparator(.hidden)
        } else {
            self
        }
    }
}

extension View {
    @ViewBuilder
    func listSectionSpacingCompactIfAvailable() -> some View {
        if #available(iOS 17.0, *) {
            self.listSectionSpacing(.compact)
        }
        else {
            self
        }
    }
}


extension View {
    @ViewBuilder
    func presentAsPopoverIfAvailable() -> some View {
        if #available(iOS 16.4, *) {
            self.presentationCompactAdaptation(.popover)
        }
        else {
            self
        }
    }
}
