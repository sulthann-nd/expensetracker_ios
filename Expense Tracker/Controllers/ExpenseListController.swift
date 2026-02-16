import CoreData
import Combine

class ExpenseListController: ObservableObject {
    @Published var selectedCategory: String = "All"
    @Published var selectedSort: String = "Date"
    @Published var selectedFilter: String = "Date range"
    @Published var expenses: [ExpenseEntity] = []
    
    let categories = ["All", "Food", "Transport", "Shopping", "Entertainment", "Bills", "Others"]
    
    private let viewContext: NSManagedObjectContext
    
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
    
    var filteredExpenses: [ExpenseEntity] {
        var list = expenses
        
        if selectedCategory != "All" {
            list = list.filter { ($0.category ?? "") == selectedCategory }
        }
        
        if selectedSort == "Amount" {
            list.sort { $0.amount > $1.amount }
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