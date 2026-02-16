//
//  DailyLineChart.swift
//  Expense Tracker
//
//  Created by Sulthan Navadeep on 11/02/26.
//

import SwiftUI

/// DailyLineChart draws a simple area + line chart with dots.
/// Provide an array of Double values (ordered left-to-right).
public struct DailyLineChart: View {
    public let values: [Double]

    public init(values: [Double]) {
        self.values = values
    }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            let rawMax = values.max() ?? 0
            let rawMin = values.min() ?? 0

            let (minV, maxV): (Double, Double) = {
                if values.isEmpty {
                    return (0.0, 1.0)
                }
                if rawMax == rawMin {
                    if rawMax == 0 {
                        return (0.0, 1.0)
                    } else {
                        let padding = abs(rawMax) * 0.05
                        return (rawMin - padding, rawMax + padding)
                    }
                } else {
                    return (rawMin, rawMax)
                }
            }()

            let range = max(maxV - minV, 1e-6)
            let stepX = w / CGFloat(max(values.count - 1, 1))

            let points: [CGPoint] = values.enumerated().map { idx, v in
                let x = CGFloat(idx) * stepX
                let normalized = (v - minV) / range
                let y = h - CGFloat(normalized) * (h - 6) - 3
                return CGPoint(x: x, y: y)
            }

            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h - 1))
                    p.addLine(to: CGPoint(x: w, y: h - 1))
                }
                .stroke(Color(.systemGray5), lineWidth: 1)

                if !points.isEmpty {
                    Path { p in
                        guard let first = points.first else { return }
                        p.move(to: first)
                        points.dropFirst().forEach { p.addLine(to: $0) }
                        p.addLine(to: CGPoint(x: points.last?.x ?? 0, y: h))
                        p.addLine(to: CGPoint(x: 0, y: h))
                        p.closeSubpath()
                    }
                    .fill(LinearGradient(colors: [Color.blue.opacity(0.18), Color.blue.opacity(0.0)],
                                         startPoint: .top,
                                         endPoint: .bottom))

                    Path { p in
                        guard let first = points.first else { return }
                        p.move(to: first)
                        points.dropFirst().forEach { p.addLine(to: $0) }
                    }
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    ForEach(points.indices, id: \.self) { i in
                        Circle()
                            .fill(Color.white)
                            .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                            .frame(width: 6, height: 6)
                            .position(points[i])
                            .shadow(color: .blue.opacity(0.18), radius: 2, x: 0, y: 1)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: values)
        }
    }
}
