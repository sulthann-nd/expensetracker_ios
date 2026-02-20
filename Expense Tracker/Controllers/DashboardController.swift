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
    @Published var isExchangeRateDataLoaded = false

    private let viewContext: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    private let exchangeRateViewModel: ExchangeRateViewModel

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        self.exchangeRateViewModel = ExchangeRateViewModel()
        fetchExpenses()
        setupNotifications()
        setupBindings()
        // Fetch exchange rates for currency conversion
        exchangeRateViewModel.loadInitialData()
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
        // Track exchange rate data loading
        exchangeRateViewModel.$latestRates
            .combineLatest(exchangeRateViewModel.$currencySymbols)
            .map { rates, symbols in
                !rates.isEmpty && !symbols.isEmpty
            }
            .assign(to: &$isExchangeRateDataLoaded)
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
            if calendar.isDateInToday(date) {
                if exchangeRateViewModel.latestRatesDictionary.isEmpty {
                    // If rates not loaded, return amount in original currency (assuming it's INR if currency is INR)
                    return e.currency == "INR" ? acc + e.amount : acc
                } else {
                    let convertedAmount = CurrencyConverter.convertToINR(from: e.currency ?? "INR", amount: e.amount, rates: exchangeRateViewModel.latestRatesDictionary)
                    return acc + convertedAmount
                }
            }
            return acc
        }
    }

    var thisMonthSpending: Double {
        let calendar = Calendar.current
        let now = Date()
        return expenses.reduce(0) { acc, e in
            guard let date = e.date else { return acc }
            let sameMonth = calendar.component(.year, from: date) == calendar.component(.year, from: now)
                && calendar.component(.month, from: date) == calendar.component(.month, from: now)
            if sameMonth {
                if exchangeRateViewModel.latestRatesDictionary.isEmpty {
                    // If rates not loaded, return amount in original currency (assuming it's INR if currency is INR)
                    return e.currency == "INR" ? acc + e.amount : acc
                } else {
                    let convertedAmount = CurrencyConverter.convertToINR(from: e.currency ?? "INR", amount: e.amount, rates: exchangeRateViewModel.latestRatesDictionary)
                    return acc + convertedAmount
                }
            }
            return acc
        }
    }

    // Public accessor for exchange rates
    var latestRatesDictionary: [String: Double] {
        exchangeRateViewModel.latestRatesDictionary
    }

    func addExpense() {
        isPresentingAdd = true
    }

    func dismissAdd() {
        isPresentingAdd = false
    }
}