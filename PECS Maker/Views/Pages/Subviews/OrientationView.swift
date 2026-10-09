//
//  OrientationView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import SharedSwiftUI

struct OrientationView: View {
    let pageSize: PageSize
    let pageOrientation: PageOrientation
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 10) {
            PaperPreview(aspectRatio: aspectRatio)
                .padding(.top, 4)
                .frame(height: 76)

            Text(pageOrientation.localizedString)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.mfVeryBrightBlue : Color.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.mfVeryBrightBlue.opacity(0.08) : Color(uiColor: .secondarySystemGroupedBackground))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Color.mfVeryBrightBlue : Color(uiColor: .separator).opacity(0.35),
                        lineWidth: isSelected ? 1.5 : 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var aspectRatio: CGFloat {
        let size = PageMeasurements2.forSize(pageSize, orientation: pageOrientation)
        return size.width / size.height
    }
}

private struct PaperPreview: View {
    let aspectRatio: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(Color(uiColor: .systemBackground))
            .overlay {
                RoundedRectangle(cornerRadius: 1.5)
                    .stroke(Color(uiColor: .secondaryLabel), lineWidth: 1.5)
            }
            .aspectRatio(aspectRatio, contentMode: .fit)
            .shadow(color: .black.opacity(0.06), radius: 1, y: 1)
    }
}
