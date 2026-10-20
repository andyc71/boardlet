//
//  OrientationView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import SharedSwiftUI

struct OrientationView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    let pageSize: PageSize
    let pageOrientation: PageOrientation
    let isSelected: Bool

    var body: some View {
        VStack(spacing: verticalSizeClass == .compact ? 6 : 10) {
            PaperPreview(aspectRatio: aspectRatio)
                .frame(height: verticalSizeClass == .compact ? 36 : 72)
                .accessibilityHidden(true)

            Text(pageOrientation.localizedString)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.mfVeryBrightBlue : Color.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, verticalSizeClass == .compact ? 8 : 12)
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
    @State private var longEdge: CGFloat = 0

    var body: some View {
        // Use the same long edge for both orientations to preserve paper proportions.
        let width = aspectRatio > 1 ? longEdge : longEdge * aspectRatio
        let height = aspectRatio > 1 ? longEdge / aspectRatio : longEdge

        Color.clear
            .onGeometryChange(for: CGFloat.self) { geometry in
                min(geometry.size.width, geometry.size.height)
            } action: { size in
                longEdge = size
            }
            .overlay {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color(uiColor: .systemBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: 1.5)
                            .stroke(Color(uiColor: .secondaryLabel), lineWidth: 1.5)
                    }
                    .frame(width: width, height: height)
                    .shadow(color: .black.opacity(0.06), radius: 1, y: 1)
            }
    }
}
