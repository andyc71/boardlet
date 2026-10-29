//
//  PageSizeSelectionView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import SharedSwiftUI

struct PageSizeSelectionView: View {
    @Binding var selectedPageSize: PageSize
    @Binding var medium: PageLayoutMedium

    init(selectedPageSize: Binding<PageSize>, medium: Binding<PageLayoutMedium> = .constant(.paper)) {
        _selectedPageSize = selectedPageSize
        _medium = medium
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(medium == .paper ? L10n.PageSizeSelectionView.title : L10n.LayoutScreen.screenLayout)
                    .font(.headline)
                    .accessibilityIdentifier(AccessibilityIdentifiers.LayoutScreen.pageSizeHeading)
                Spacer(minLength: 12)
                if InterfaceStyle.canChange {
                    Picker(L10n.LayoutScreen.medium, selection: $medium) {
                        Text(L10n.LayoutScreen.paper).tag(PageLayoutMedium.paper)
                        Text(L10n.LayoutScreen.screen).tag(PageLayoutMedium.screen)
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("LayoutScreen.medium")
                } else {
                    Text(L10n.LayoutScreen.paper)
                        .accessibilityIdentifier("LayoutScreen.mediumLabel")
                }
            }
            .font(.headline)
            .foregroundStyle(.secondary)
            .tint(Color(uiColor: .secondaryLabel))
            .padding(.horizontal, 12)
            if medium == .paper {
                pageSizeMenu
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pageSizeMenu: some View {
        Menu {
            ForEach(PageSize.allCases) { pageSize in
                Button {
                    selectedPageSize = pageSize
                } label: {
                    Text(pageSize.localizedString)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.LayoutScreen.pageSizeButton(for: pageSize))
                .if(pageSize == selectedPageSize) { view in
                    view.accessibility(addTraits: .isSelected)
                }
            }
        } label: {
            HStack(spacing: 12) {
                Text(selectedPageSize.dimensionsDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 12)

                Text(selectedPageSize.localizedString)
                    .font(.headline)
                    .foregroundStyle(Color.mfVeryBrightBlue)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.mfVeryBrightBlue)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .tint(.mfVeryBrightBlue)
        .accessibilityIdentifier("LayoutScreen.paperSizeMenu")
        .accessibilityLabel(L10n.PageSizeSelectionView.title)
        .accessibilityValue(selectedPageSize.localizedString)
    }
}

private extension PageSize {
    var dimensionsDescription: String {
        let size = PageMeasurements2.forSize(self)
        let width = Double(size.width).formatted(.number.precision(.fractionLength(0...1)))
        let height = Double(size.height).formatted(.number.precision(.fractionLength(0...1)))
        return "\(width) × \(height) mm"
    }
}

struct PageSizeSelectionView_Previews: PreviewProvider {
    
    @State static var selectedPageSize = PageSize.a4
    
    static var previews: some View {
        PageSizeSelectionView(selectedPageSize: $selectedPageSize)
    }
}
