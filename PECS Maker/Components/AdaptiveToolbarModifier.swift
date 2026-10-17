//
//  AdaptiveToolbarModifier.swift
//  PECS Maker
//
//  Created by Andy on 15/10/2026.
//

import SwiftUI

// MARK: - Adaptive Toolbar

private struct AdaptiveToolbarModifier<ToolbarContent: View>: ViewModifier {
    let isHorizontal: Bool
    let toolbarContent: () -> ToolbarContent

    func body(content: Content) -> some View {
        if isHorizontal {
            content.safeAreaInset(edge: .bottom, spacing: 0) {
                horizontalToolbar
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
                    .padding(.top, 4)
            }
        } else {
            content.safeAreaInset(edge: .trailing, spacing: 0) {
                verticalToolbar
            }
        }
    }

    // Portrait: floating rounded glass bar
    private var horizontalToolbar: some View {
        HStack(spacing: 0) {
            toolbarContent()
        }
        .adaptiveToolbarButtonStyle(isHorizontal: true)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
            .fill(.regularMaterial)
            .shadow(
                color: .black.opacity(0.08),
                radius: 12,
                y: 3
            )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(
                    .white.opacity(0.65),
                    lineWidth: 1
                )
        }
    }

    // Landscape: narrow, trailing glass rail
    private var verticalToolbar: some View {
        VStack(spacing: 2) {
            toolbarContent()
        }
        .adaptiveToolbarButtonStyle(isHorizontal: false)
        .frame(width: 92)
        .frame(maxHeight: .infinity)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 28,
                bottomLeadingRadius: 28,
                style: .continuous
            )
            .fill(.regularMaterial)
            .ignoresSafeArea(edges: .trailing)
        }
    }
}

// MARK: - Button Style

struct AdaptiveToolbarButtonStyle: ButtonStyle {
    let isHorizontal: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(AdaptiveToolbarLabelStyle())
            .frame(
                maxWidth: isHorizontal ? .infinity : nil
            )
            .frame(
                width: isHorizontal ? nil : 80,
                height: isHorizontal ? 64 : 72
            )
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.55 : 1)
            .animation(
                .easeOut(duration: 0.15),
                value: configuration.isPressed
            )
    }
}

// MARK: - Label Style

private struct AdaptiveToolbarLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 5) {
            configuration.icon
                .font(.system(size: 22))
                .foregroundStyle(.blue)

            configuration.title
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }
}

// MARK: - Public API

extension View {
    func adaptiveToolbar<ToolbarContent: View>(
        isHorizontal: Bool,
        @ViewBuilder content: @escaping () -> ToolbarContent
    ) -> some View {
        modifier(
            AdaptiveToolbarModifier(
                isHorizontal: isHorizontal,
                toolbarContent: content
            )
        )
    }

    func adaptiveToolbarButtonStyle(
        isHorizontal: Bool
    ) -> some View {
        buttonStyle(
            AdaptiveToolbarButtonStyle(
                isHorizontal: isHorizontal
            )
        )
    }
}
