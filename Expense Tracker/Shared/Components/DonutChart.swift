import SwiftUI

/// DonutChart renders a donut with labeled center for the largest slice.
/// Accepts an array of `CategorySlice` from Shared/Components/CategorySlice.swift.
public struct DonutChart: View {
    public let slices: [CategorySlice]

    public init(slices: [CategorySlice]) {
        self.slices = slices
    }

    public var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let lineWidth = size * 0.24

            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: lineWidth)

                DonutSegmentsView(slices: slices, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))

                if let largest = slices.max(by: { $0.percent < $1.percent }) {
                    VStack(spacing: 4) {
                        Text("\(Int(largest.percent * 100))%")
                            .font(.title3.weight(.bold))
                        Text(largest.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
            }
        }
    }
}

private struct DonutSegmentsView: View {
    let slices: [CategorySlice]
    let style: StrokeStyle

    var body: some View {
        GeometryReader { geo in
            let segments: [(start: Angle, end: Angle, color: Color)] = {
                var start = Angle(degrees: -90)
                return slices.map { slice in
                    let span = Angle(degrees: 360 * slice.percent)
                    let seg = (start: start, end: start + span, color: slice.color)
                    start += span
                    return seg
                }
            }()

            ZStack {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                    DonutSegment(startAngle: seg.start, endAngle: seg.end)
                        .stroke(seg.color, style: style)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct DonutSegment: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.addArc(center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)
        return path
    }
}
