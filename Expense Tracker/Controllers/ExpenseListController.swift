import CoreData
import Combine

class ExpenseListController: ObservableObject {
    @Published var selectedCategory: String = "All"
    @Published var selectedSort: String = "Date"
    @Published var selectedFilter: String = "Date range"
    @Published var expenses: [ExpenseEntity] = []
    
    let categories = ["All", "Food", "Transport", "Shopping", "Entertainment", "Bills", "Others"]
    
    private let viewContext: NSManagedObjectContext
    private let exchangeRateViewModel: ExchangeRateViewModel
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        self.exchangeRateViewModel = ExchangeRateViewModel()
        fetchExpenses()
        setupNotifications()
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
    
    func fetchExpenses() {
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExpenseEntity.date, ascending: false)]
        do {
            expenses = try viewContext.fetch(request)
        } catch {
            print("Error fetching expenses: \(error)")
        }
    }
    
    var filteredExpenses: [ExpenseEntity] {
        var list = expenses
        
        if selectedCategory != "All" {
            list = list.filter { ($0.category ?? "") == selectedCategory }
        }
        
        if selectedSort == "Amount" {
            list.sort { 
                let amount1: Double
                let amount2: Double
                if exchangeRateViewModel.latestRatesDictionary.isEmpty {
                    // If rates not loaded, sort by original amount
                    amount1 = $0.amount
                    amount2 = $1.amount
                } else {
                    amount1 = CurrencyConverter.convertToINR(from: $0.currency ?? "INR", amount: $0.amount, rates: exchangeRateViewModel.latestRatesDictionary)
                    amount2 = CurrencyConverter.convertToINR(from: $1.currency ?? "INR", amount: $1.amount, rates: exchangeRateViewModel.latestRatesDictionary)
                }
                return amount1 > amount2
            }
        } else {
            list.sort { ($0.date ?? Date()) > ($1.date ?? Date()) }
        }
        
        return list
    }
    
    var groupedByDate: [(key: Date, values: [ExpenseEntity])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filteredExpenses) { (e: ExpenseEntity) -> Date in
            guard let d = e.date else { return calendar.startOfDay(for: Date.distantPast) }
            return calendar.startOfDay(for: d)
        }
        return groups
            .map { (key: $0.key, values: $0.value) }
            .sorted { $0.key > $1.key }
    }
    
    var groupedByCategory: [(key: String, values: [ExpenseEntity])] {
        let groups = Dictionary(grouping: filteredExpenses) { $0.category ?? "Others" }
        return groups
            .map { (key: $0.key, values: $0.value.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }) }
            .sorted { $0.key < $1.key }
    }
    
    // Public accessor for exchange rates
    var latestRatesDictionary: [String: Double] {
        exchangeRateViewModel.latestRatesDictionary
    }
    
    func deleteExpense(_ expense: ExpenseEntity) {
        viewContext.delete(expense)
        do {
            try viewContext.save()
            fetchExpenses()
        } catch {
            print("Error deleting expense: \(error)")
        }
    }
}