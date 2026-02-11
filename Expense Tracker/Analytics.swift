import SwiftUI
import CoreData

struct Analytics: View {
    struct CategorySlice: Identifiable {
        let id = UUID()
        let name: String
        let percent: Double
        let color: Color
    }

    @Environment(\.managedObjectContext) private var viewContext

    // Fetch all expenses (we will filter by selected month)
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ExpenseEntity.date, ascending: false)],
        animation: .default
    ) private var allExpenses: FetchedResults<ExpenseEntity>

    // Selected month (we store a Date but only month/year are used)
    @State private var selectedMonthDate: Date = Date()
    @State private var isMonthPickerPresented: Bool = false

    // Category ordering and colors
    private let categoriesOrder: [String] = ["Food", "Shopping", "Transport", "Entertainment", "Bills", "Others"]

    // MARK: - Filtered expenses for selected month
    private var filteredExpenses: [ExpenseEntity] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedMonthDate)
        guard let year = components.year, let month = components.month else { return [] }

        return allExpenses.filter { e in
            guard let d = e.date else { return false }
            let c = calendar.dateComponents([.year, .month], from: d)
            return c.year == year && c.month == month
        }
    }

    // MARK: - Aggregations based on filteredExpenses

    private var totalAmount: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    private var categoryTotals: [String: Double] {
        var dict: [String: Double] = [:]
        for e in filteredExpenses {
            let cat = e.category ?? "Others"
            dict[cat, default: 0] += e.amount
        }
        return dict
    }

    private var slices: [CategorySlice] {
        let total = categoryTotals.values.reduce(0, +)
        guard total > 0 else {
            return [CategorySlice(name: "No Data", percent: 1.0, color: .gray)]
        }

        var orderedKeys = categoriesOrder.filter { categoryTotals[$0] != nil }
        let extras = categoryTotals.keys.filter { !orderedKeys.contains($0) }
        orderedKeys.append(contentsOf: extras)

        return orderedKeys.map { key in
            let value = categoryTotals[key] ?? 0
            return CategorySlice(name: key, percent: value / total, color: color(for: key))
        }
    }

    // Returns an array of totals for each of the last `days` days.
    // The last element corresponds to the last day of the selected month (or today if current month).
    private func dailySeries(days: Int = 7) -> [Double] {
        let calendar = Calendar.current

        // Determine the end day: end of selected month, but if selected month is current month use today
        guard let selectedMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonthDate)) else { return [] }
        let isSelectedMonthCurrent = calendar.isDate(selectedMonthStart, equalTo: Date(), toGranularity: .month) &&
                                     calendar.isDate(selectedMonthStart, equalTo: Date(), toGranularity: .year)

        let monthEnd: Date = {
            if isSelectedMonthCurrent {
                return Date() // up to now for current month
            } else {
                var comps = DateComponents()
                comps.month = 1
                comps.day = -1
                return calendar.date(byAdding: comps, to: selectedMonthStart) ?? Date()
            }
        }()

        // Build days ending at monthEnd
        var series: [Double] = []
        for offset in (0..<days).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: monthEnd)) else {
                series.append(0)
                continue
            }
            let startOfDay = calendar.startOfDay(for: day)
            guard let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                series.append(0)
                continue
            }

            // Sum filteredExpenses that fall within [startOfDay, startOfNextDay)
            let sum = filteredExpenses.reduce(0) { acc, e in
                guard let d = e.date else { return acc }
                return (d >= startOfDay && d < startOfNextDay) ? acc + e.amount : acc
            }
            series.append(sum)
        }

        return series
    }

    // Average daily spend over the last `days` days (uses dailySeries).
    // Returns mean across the requested days (including zero days).
    private func averageDailySpend(days: Int = 7) -> Double {
        let series = dailySeries(days: days)
        guard !series.isEmpty else { return 0 }
        let total = series.reduce(0, +)
        return total / Double(series.count)
    }


    private var topCategory: String {
        categoryTotals.max(by: { $0.value < $1.value })?.key ?? "—"
    }


    private var totalThisMonth: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Month selector as a button
                    HStack {
                        Button(action: { isMonthPickerPresented = true }) {
                            HStack(spacing: 8) {
                                Text(monthYearString(from: selectedMonthDate))
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

                        HStack(alignment: .center, spacing: 16) {
                            DonutChart(slices: slices)
                                .frame(width: 140, height: 140)

                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(slices) { slice in
                                    HStack {
                                        LegendDot(color: slice.color)
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
                    }
                    .padding(30)
                    .modifier(CardBackground())

                    // Daily spending for last 7 days (relative to selected month)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Spending (Last 7 days)")
                            .font(.headline)

                        DailyLineChart(values: dailySeries(days: 7))
                            .frame(height: 120)
                    }
                    .padding()
                    .modifier(CardBackground())

                    // Summary
                    VStack(spacing: 12) {
                        SummaryRow(title: "Top Category", value: topCategory)
                        Divider()
                        SummaryRow(title: "Average Daily Spend", value: currencyString(averageDailySpend(days: 7)))
                        Divider()
                        SummaryRow(title: "Total This Month", value: currencyString(totalThisMonth), highlight: true)
                    }
                    .padding()
                    .modifier(CardBackground())

                    Spacer()
                }
                .padding(.bottom)
            }
        }
        .sheet(isPresented: $isMonthPickerPresented) {
            MonthPickerSheet(selectedDate: $selectedMonthDate)
                .presentationDetents([.medium])
        }
    }

    // MARK: - Helpers

    private func monthYearString(from date: Date) -> String {
        let fmt = Self.monthYearFormatter
        return fmt.string(from: date)
    }

    private static let monthYearFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "LLLL yyyy" // e.g., February 2026
        return fmt
    }()

    private func currencyString(_ value: Double) -> String {
        let code = Locale.current.currency?.identifier ?? "USD"
        return value.formatted(.currency(code: code))
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

private struct MonthPickerSheet: View {
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

private struct SummaryRow: View {
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

private struct LegendDot: View {
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

private struct CardBackground: ViewModifier {
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

private struct DonutChart: View {
    let slices: [Analytics.CategorySlice]

    var body: some View {
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

private struct DailyLineChart: View {
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


