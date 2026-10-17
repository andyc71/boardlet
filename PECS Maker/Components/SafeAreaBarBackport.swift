//
//  FloatingSafeAreaBar.swift
//  PECS Maker
//
//  Created by Andy on 15/10/2026.
//


import SwiftUI

extension View {

    // MARK: - Top / Bottom

    @ViewBuilder
    func safeAreaBarBackport<Content: View>(
        edge: VerticalEdge,
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if #available(iOS 26.0, *) {
            self.safeAreaBar(
                edge: edge,
                alignment: alignment,
                spacing: spacing,
                content: content
            )
        } else {
            self.safeAreaInset(
                edge: edge,
                alignment: alignment,
                spacing: spacing,
                content: content
            )
        }
    }

    // MARK: - Leading / Trailing

    @ViewBuilder
    func safeAreaBarBackport<Content: View>(
        edge: HorizontalEdge,
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if #available(iOS 26.0, *) {
            self.safeAreaBar(
                edge: edge,
                alignment: alignment,
                spacing: spacing,
                content: content
            )
        } else {
            self.safeAreaInset(
                edge: edge,
                alignment: alignment,
                spacing: spacing,
                content: content
            )
        }
    }
}
