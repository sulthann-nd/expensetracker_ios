//
//  AnalyticsController.swift
//  Expense Tracker
//
//  Created by Assistant on 16/02/26.
//

import SwiftUI
import CoreData
import Combine

class AnalyticsController: ObservableObject {
    @Published var selectedMonthDate: Date = Date()
    @Published var isMonthPickerPresented: Bool = false
    @Published var allExpenses: [ExpenseEntity] = []

    private let viewContext: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    let categoriesOrder: [String] = ["Food", "Shopping", "Transport", "Entertainment", "Bills", "Others"]

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchExpenses()
        setupBindings()
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNotifications() {
        // Listen for Core Data context save notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidSave(_:)),
            name: .NSManagedObjectContextDidSave,
            object: viewContext
        )
    }
    
    @objc private func contextDidSave(_ notification: Notification) {
        // Refetch expenses when context is saved (after add/edit/delete)
        fetchExpenses()
    }

    private func setupBindings() {
        $selectedMonthDate
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func fetchExpenses() {
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExpenseEntity.date, ascending: false)]
        do {
            allExpenses = try viewContext.fetch(request)
        } catch {
            print("Error fetching expenses: \(error)")
        }
    }

    var filteredExpenses: [ExpenseEntity] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedMonthDate)
        guard let year = components.year, let month = components.month else { return [] }

        return allExpenses.filter { e in
            guard let d = e.date else { return false }
            let c = calendar.dateComponents([.year, .month], from: d)
            return c.year == year && c.month == month
        }
    }

    var totalAmount: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    var categoryTotals: [String: Double] {
        var dict: [String: Double] = [:]
        for e in filteredExpenses {
            let cat = e.category ?? "Others"
            dict[cat, default: 0] += e.amount
        }
        return dict
    }

    var slices: [Analytics.CategorySlice] {
        let total = categoryTotals.values.reduce(0, +)
        guard total > 0 else {
            return [Analytics.CategorySlice(name: "No Data", percent: 1.0, color: .gray)]
        }

        var orderedKeys = categoriesOrder.filter { categoryTotals[$0] != nil }
        let extras = categoryTotals.keys.filter { !orderedKeys.contains($0) }
        orderedKeys.append(contentsOf: extras)

        return orderedKeys.map { key in
            let value = categoryTotals[key] ?? 0
            return Analytics.CategorySlice(name: key, percent: value / total, color: color(for: key))
        }
    }

    func dailySeries(days: Int = 7) -> [Double] {
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

    func averageDailySpend(days: Int = 7) -> Double {
        let series = dailySeries(days: days)
        guard !series.isEmpty else { return 0 }
        let total = series.reduce(0, +)
        return total / Double(series.count)
    }

    var topCategory: String {
        categoryTotals.max(by: { $0.value < $1.value })?.key ?? "—"
    }

    var totalThisMonth: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    func monthYearString(from date: Date) -> String {
        Self.monthYearFormatter.string(from: date)
    }

    private static let monthYearFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "LLLL yyyy" // e.g., February 2026
        return fmt
    }()

    func currencyString(_ value: Double) -> String {
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