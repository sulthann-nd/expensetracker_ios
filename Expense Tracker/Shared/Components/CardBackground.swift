//
//  CardBackground.swift
//  Expense Tracker
//
//  Created by Sulthan Navadeep on 11/02/26.
//

import SwiftUI

public struct CardBackground: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            .padding(.horizontal)
    }
}

public extension View {
    func cardBackground() -> some View {
        self.modifier(CardBackground())
    }
}
