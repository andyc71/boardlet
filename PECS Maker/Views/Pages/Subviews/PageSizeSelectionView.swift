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

    var body: some View {
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
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.PageSizeSelectionView.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .accessibilityIdentifier(AccessibilityIdentifiers.LayoutScreen.pageSizeHeading)

                    Text(selectedPageSize.dimensionsDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Text(selectedPageSize.localizedString)
                    .font(.headline)
                    .foregroundStyle(Color.mfVeryBrightBlue)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.mfVeryBrightBlue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .tint(.mfVeryBrightBlue)
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
