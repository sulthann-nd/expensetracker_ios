//
//  CategorySlice.swift
//  Expense Tracker
//
//  Created by Sulthan Navadeep on 11/02/26.
//

import SwiftUI

/// Shared model for chart slices used by DonutChart and other components.
public struct CategorySlice: Identifiable {
    public let id: UUID
    public let name: String
    public let percent: Double
    public let color: Color

    public init(id: UUID = UUID(), name: String, percent: Double, color: Color) {
        self.id = id
        self.name = name
        self.percent = percent
        self.color = color
    }
}
