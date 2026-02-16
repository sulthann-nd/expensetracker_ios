//
//  SummaryRow.swift
//  Expense Tracker
//
//  Created by Sulthan Navadeep on 11/02/26.
//

import SwiftUI

public struct SummaryRow: View {
    public let title: String
    public let value: String
    public let highlight: Bool

    public init(title: String, value: String, highlight: Bool = false) {
        self.title = title
        self.value = value
        self.highlight = highlight
    }

    public var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(highlight ? Color.blue : Color.primary)
        }
    }
}
