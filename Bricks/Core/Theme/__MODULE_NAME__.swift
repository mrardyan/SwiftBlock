import SwiftUI

/// Central design system tokens used across the application.
public struct __MODULE_NAME__ {
    public static let shared = __MODULE_NAME__()

    public let primaryColor: Color
    public let secondaryColor: Color
    public let backgroundColor: Color
    public let surfaceColor: Color
    public let textColor: Color
    public let errorColor: Color
    public let successColor: Color

    public let cornerRadiusSmall: CGFloat
    public let cornerRadius: CGFloat
    public let cornerRadiusLarge: CGFloat

    public let spacingExtraSmall: CGFloat
    public let spacingSmall: CGFloat
    public let spacing: CGFloat
    public let spacingLarge: CGFloat

    public let bodyFont: Font
    public let headlineFont: Font
    public let titleFont: Font

    public init(
        primaryColor: Color = .blue,
        secondaryColor: Color = .gray,
        backgroundColor: Color = Color(.sRGB, red: 0.96, green: 0.96, blue: 0.97),
        surfaceColor: Color = .white,
        textColor: Color = .primary,
        errorColor: Color = .red,
        successColor: Color = .green,
        cornerRadiusSmall: CGFloat = 6,
        cornerRadius: CGFloat = 12,
        cornerRadiusLarge: CGFloat = 20,
        spacingExtraSmall: CGFloat = 4,
        spacingSmall: CGFloat = 8,
        spacing: CGFloat = 16,
        spacingLarge: CGFloat = 24,
        bodyFont: Font = .body,
        headlineFont: Font = .headline,
        titleFont: Font = .title
    ) {
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.backgroundColor = backgroundColor
        self.surfaceColor = surfaceColor
        self.textColor = textColor
        self.errorColor = errorColor
        self.successColor = successColor
        self.cornerRadiusSmall = cornerRadiusSmall
        self.cornerRadius = cornerRadius
        self.cornerRadiusLarge = cornerRadiusLarge
        self.spacingExtraSmall = spacingExtraSmall
        self.spacingSmall = spacingSmall
        self.spacing = spacing
        self.spacingLarge = spacingLarge
        self.bodyFont = bodyFont
        self.headlineFont = headlineFont
        self.titleFont = titleFont
    }
}