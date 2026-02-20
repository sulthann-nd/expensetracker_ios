import SwiftUI
import CoreData

struct Analytics: View {
    struct CategorySlice: Identifiable {
        let id = UUID()
        let name: String
        let percent: Double
        let color: Color
    }

    @StateObject private var controller: AnalyticsController

    init(context: NSManagedObjectContext? = nil) {
        let ctx = context ?? PersistenceController.shared.container.viewContext
        _controller = StateObject(wrappedValue: AnalyticsController(context: ctx))
    }

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Month selector as a button
                    HStack {
                        Button(action: { controller.isMonthPickerPresented = true }) {
                            HStack(spacing: 8) {
                                Text(controller.monthYearString(from: controller.selectedMonthDate))
                                    .font(.headline)
                                Image(systemName: "chevron.down")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemBackground)))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4)))
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Donut + legend
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Spending by Category")
                            .font(.headline)
                            .padding(.bottom, 10)

                        if controller.isExchangeRateDataLoaded {
                            HStack(alignment: .center, spacing: 16) {
                                AnalyticsDonutChart(slices: controller.slices)
                                    .frame(width: 140, height: 140)

                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(controller.slices) { slice in
                                        HStack {
                                            AnalyticsLegendDot(color: slice.color)
                                                .padding(.horizontal, 10)
                                            Text(slice.name)
                                                .font(.subheadline)
                                            Spacer()
                                            Text("\(Int(slice.percent * 100))%")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    ProgressView()
                                    Text("Loading chart data...")
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                }
                                Spacer()
                            }
                            .frame(height: 140)
                        }
                    }
                    .padding(30)
                    .modifier(AnalyticsCardBackground())

                    // Daily spending for last 7 days (relative to selected month)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Spending (Last 7 days)")
                            .font(.headline)

                        if controller.isExchangeRateDataLoaded {
                            AnalyticsDailyLineChart(values: controller.dailySeries(days: 7))
                                .frame(height: 120)
                        } else {
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    ProgressView()
                                    Text("Loading daily spending data...")
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                }
                                Spacer()
                            }
                            .frame(height: 120)
                        }
                    }
                    .padding()
                    .modifier(AnalyticsCardBackground())

                    // Summary
                    VStack(spacing: 12) {
                        if controller.isExchangeRateDataLoaded {
                            AnalyticsSummaryRow(title: "Top Category", value: controller.topCategory)
                            Divider()
                            AnalyticsSummaryRow(title: "Average Daily Spend", value: controller.currencyString(controller.averageDailySpend(days: 7)))
                            Divider()
                            AnalyticsSummaryRow(title: "Total This Month", value: controller.currencyString(controller.totalThisMonth), highlight: true)
                        } else {
                            HStack {
                                Text("Loading exchange rate data...")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                ProgressView()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    .modifier(AnalyticsCardBackground())

                    Spacer()
                }
                .padding(.bottom)
            }
        }
        .sheet(isPresented: $controller.isMonthPickerPresented) {
            AnalyticsMonthPickerSheet(selectedDate: $controller.selectedMonthDate)
                .presentationDetents([.medium])
        }
    }

    // MARK: - Helpers

    private func monthYearString(from date: Date) -> String {
        controller.monthYearString(from: date)
    }

    private func currencyString(_ value: Double) -> String {
        controller.currencyString(value)
    }
 
    private func color(for category: String?) -> Color {
        switch category {
        case "Shopping": return .green
        case "Food": return .orange
        case "Transport": return .blue
        case "Entertainment": return .red
        case "Bills": return .purple
        case "Others": return .gray
        default: return .gray
        }
    }
}

// MonthPickerSheet.swift

private struct AnalyticsMonthPickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    // Build month names and a reasonable year range
    private let months: [String] = {
        let fmt = DateFormatter()
        return fmt.monthSymbols
    }()

    private let years: [Int] = {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        // adjust range as needed
        return Array((currentYear - 10)...(currentYear + 5))
    }()

    // Local selection state (month index 0...11, year value)
    @State private var selectedMonthIndex: Int = 0
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    var body: some View {
        VStack(spacing: 16) {
            Text("Select Month")
                .font(.headline)
                .padding(.top)

            HStack {
                // Month picker
                Picker(selection: $selectedMonthIndex, label: Text("Month")) {
                    ForEach(months.indices, id: \.self) { idx in
                        Text(months[idx]).tag(idx)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                // Year picker
                Picker(selection: $selectedYear, label: Text("Year")) {
                    ForEach(years, id: \.self) { y in
                        Text("\(y)").tag(y)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
            }
            .frame(height: 200)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .padding()

                Spacer()

                Button("Done") {
                    // Normalize to first day of selected month/year
                    var comps = DateComponents()
                    comps.year = selectedYear
                    comps.month = selectedMonthIndex + 1
                    comps.day = 1
                    if let normalized = Calendar.current.date(from: comps) {
                        selectedDate = normalized
                    }
                    dismiss()
                }
                .padding()
            }
        }
        .padding()
        .onAppear {
            // Initialize pickers from the bound selectedDate
            let calendar = Calendar.current
            let comps = calendar.dateComponents([.year, .month], from: selectedDate)
            if let month = comps.month {
                selectedMonthIndex = max(0, min(11, month - 1))
            }
            if let year = comps.year {
                // if the year is outside our years array, clamp to nearest
                if years.contains(year) {
                    selectedYear = year
                } else if year < years.first! {
                    selectedYear = years.first!
                } else {
                    selectedYear = years.last!
                }
            }
        }
    }
}


// MARK: - Reused subviews (LegendDot, CardBackground, DonutChart, DailyLineChart, SummaryRow)
// Copy your existing implementations below (unchanged). For brevity they are included here:

private struct AnalyticsSummaryRow: View {
    let title: String
    let value: String
    var highlight: Bool = false

    var body: some View {
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

private struct AnalyticsLegendDot: View {
    let color: Color
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .overlay(
                Circle().stroke(Color.white, lineWidth: 1)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            )
    }
}

private struct AnalyticsCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            .padding(.horizontal)
    }
}

private struct AnalyticsDonutChart: View {
    let slices: [Analytics.CategorySlice]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let lineWidth = size * 0.24

            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: lineWidth)

                AnalyticsDonutSegmentsView(slices: slices, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))

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

private struct AnalyticsDonutSegmentsView: View {
    let slices: [Analytics.CategorySlice]
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
                    AnalyticsDonutSegment(startAngle: seg.start, endAngle: seg.end)
                        .stroke(seg.color, style: style)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct AnalyticsDonutSegment: Shape {
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

private struct AnalyticsDailyLineChart: View {
    let values: [Double]

    var body: some View {
        GeometryReader { geo in
            // compute geometry and math up front
            let w = geo.size.width
            let h = geo.size.height

            // safe handling for empty input
            let rawMax = values.max() ?? 0
            let rawMin = values.min() ?? 0

            // determine a visible range even when all values are equal
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

            // map values to points (safe even for empty values)
            let points: [CGPoint] = values.enumerated().map { idx, v in
                let x = CGFloat(idx) * stepX
                let normalized = (v - minV) / range
                // inset top/bottom so line/dots are visible
                let y = h - CGFloat(normalized) * (h - 6) - 3
                return CGPoint(x: x, y: y)
            }

            // Build the view without using `return`
            ZStack {
                // Baseline
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h - 1))
                    p.addLine(to: CGPoint(x: w, y: h - 1))
                }
                .stroke(Color(.systemGray5), lineWidth: 1)

                if points.isEmpty {
                    // Empty state: show a faint baseline only
                    EmptyView()
                } else {
                    // Area fill
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

                    // Line
                    Path { p in
                        guard let first = points.first else { return }
                        p.move(to: first)
                        points.dropFirst().forEach { p.addLine(to: $0) }
                    }
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    // Dots
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

