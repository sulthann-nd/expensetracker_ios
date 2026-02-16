//
//  DashboardController.swift
//  Expense Tracker
//
//  Created by Assistant on 16/02/26.
//

import SwiftUI
import CoreData
import Combine

class DashboardController: ObservableObject {
    @Published var isPresentingAdd: Bool = false
    @Published var expenses: [ExpenseEntity] = []

    private let viewContext: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchExpenses()
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

    func fetchExpenses() {
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExpenseEntity.date, ascending: false)]
        do {
            expenses = try viewContext.fetch(request)
        } catch {
            print("Error fetching expenses: \(error)")
        }
    }

    var todaysSpending: Double {
        let calendar = Calendar.current
        return expenses.reduce(0) { acc, e in
            guard let date = e.date else { return acc }
            return calendar.isDateInToday(date) ? acc + e.amount : acc
        }
    }

    var thisMonthSpending: Double {
        let calendar = Calendar.current
        let now = Date()
        return expenses.reduce(0) { acc, e in
            guard let date = e.date else { return acc }
            let sameMonth = calendar.component(.year, from: date) == calendar.component(.year, from: now)
                && calendar.component(.month, from: date) == calendar.component(.month, from: now)
            return sameMonth ? acc + e.amount : acc
        }
    }

    func addExpense() {
        isPresentingAdd = true
    }

    func dismissAdd() {
        isPresentingAdd = false
    }
}