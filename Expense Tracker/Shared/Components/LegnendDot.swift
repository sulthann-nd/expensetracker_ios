//
//  LegnendDot.swift
//  Expense Tracker
//
//  Created by Sulthan Navadeep on 11/02/26.
//

import SwiftUI

public struct LegendDot: View {
    public let color: Color

    public init(color: Color) {
        self.color = color
    }

    public var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 1)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            )
    }
}
