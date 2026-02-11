import SwiftUI
import CoreData

struct ExpenseListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var selectedCategory: String = "All"
    @State private var selectedSort: String = "Date"
    @State private var selectedFilter: String = "Date range"

    let categories = ["All", "Food", "Transport", "Shopping", "Entertainment", "Bills", "Others"]

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ExpenseEntity.date, ascending: false)],
        animation: .default
    ) private var expenses: FetchedResults<ExpenseEntity>

    // MARK: - Grouping helpers

    // Filtered and optionally sorted flat list
    private var filteredExpenses: [ExpenseEntity] {
        var list = expenses.map { $0 }

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

    // Group by day (startOfDay) -> sorted keys descending
    private var groupedByDate: [(key: Date, values: [ExpenseEntity])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filteredExpenses) { (e: ExpenseEntity) -> Date in
            guard let d = e.date else { return calendar.startOfDay(for: Date.distantPast) }
            return calendar.startOfDay(for: d)
        }
        return groups
            .map { (key: $0.key, values: $0.value) }
            .sorted { $0.key > $1.key }
    }

    // Group by category -> sorted by category name
    private var groupedByCategory: [(key: String, values: [ExpenseEntity])] {
        let groups = Dictionary(grouping: filteredExpenses) { ($0.category ?? "Others") }
        return groups
            .map { (key: $0.key, values: $0.value) }
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Text("Expense List")
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                            .bold()
                        Spacer()
                    }
                    .padding(.bottom, 16)
                }
                .background(Color.blue)

                // Category Scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(categories, id: \.self) { category in
                            Button(action: { selectedCategory = category }) {
                                Text(category)
                                    .font(.system(size: 16, weight: .regular))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .frame(minWidth: 100, minHeight: 40)
                                    .foregroundStyle(selectedCategory == category ? .white : .primary)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedCategory == category ? Color.blue : Color.gray.opacity(0.1))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(Color.white)

                // Sort & Filter Bar
                HStack {
                    HStack(spacing: 4) {
                        Text("Sort by")
                            .foregroundColor(.secondary)

                        Button("Date") { selectedSort = "Date" }
                            .foregroundColor(selectedSort == "Date" ? .blue : .primary)
                            .fontWeight(selectedSort == "Date" ? .bold : .regular)

                        Text("/")
                            .foregroundColor(.secondary)

                        Button("Amount") { selectedSort = "Amount" }
                            .foregroundColor(selectedSort == "Amount" ? .blue : .primary)
                            .fontWeight(selectedSort == "Amount" ? .bold : .regular)
                    }

                    Spacer()

                    Menu {
                        Button("Date range") { selectedFilter = "Date range" }
                        Button("Category") { selectedFilter = "Category" }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedFilter)
                            Image(systemName: "chevron.down")
                        }
                        .foregroundColor(.black)
                        .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))

                // Expense list
                if filteredExpenses.isEmpty {
                    VStack {
                        Spacer()
                        Text("No expenses yet")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            if selectedFilter == "Date range" {
                                // Group by date
                                ForEach(groupedByDate, id: \.key) { group in
                                    SectionHeaderDate(date: group.key)
                                        .padding(.top, 8)
                                        .padding(.horizontal)

                                    ForEach(group.values, id: \.objectID) { item in
                                        expenseRow(for: item)
                                        Divider().padding(.leading, 50)
                                    }
                                }
                            } else {
                                // Group by category
                                ForEach(groupedByCategory, id: \.key) { group in
                                    SectionHeaderCategory(title: group.key)
                                        .padding(.top, 8)
                                        .padding(.horizontal)

                                    ForEach(group.values, id: \.objectID) { item in
                                        expenseRow(for: item)
                                        Divider().padding(.leading, 50)
                                    }
                                }
                            }
                        }
                    }
                    .navigationDestination(for: NSManagedObjectID.self) { objectID in
                        EditExpenseView(expenseID: objectID)
                            .navigationTitle("Edit Expense")
                    }
                }
            }
        }
    }

    // MARK: - Row builder
    @ViewBuilder
    private func expenseRow(for item: ExpenseEntity) -> some View {
        NavigationLink(value: item.objectID) {
            HStack(spacing: 12) {
                Image(systemName: iconName(for: item.category))
                    .foregroundColor(.blue)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.note ?? (item.category ?? "Unknown"))
                        .font(.body)
                    if let date = item.date {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(item.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .fontWeight(.semibold)
                    Text(item.paymentMethod ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.white)
        }
        .swipeActions(edge: .trailing) {
            Button {
                openEditSheet(for: item)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)

            Button(role: .destructive) {
                deleteExpense(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Section headers

    private struct SectionHeaderDate: View {
        let date: Date
        var body: some View {
            HStack {
                Text(headerTitle(for: date))
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
        }

        private func headerTitle(for date: Date) -> String {
            let calendar = Calendar.current
            if calendar.isDateInToday(date) { return "Today" }
            if calendar.isDateInYesterday(date) { return "Yesterday" }
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            return fmt.string(from: date)
        }
    }

    private struct SectionHeaderCategory: View {
        let title: String
        var body: some View {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
        }
    }

    // MARK: - Helpers

    private func iconName(for category: String?) -> String {
        switch category {
        case "Shopping": return "cart.fill"
        case "Food": return "fork.knife"
        case "Transport": return "car.fill"
        case "Entertainment": return "gamecontroller.fill"
        case "Bills": return "doc.text.fill"
        case "Others": return "square.grid.2x2"
        default: return "tag.fill"
        }
    }

    private func deleteExpense(_ expense: ExpenseEntity) {
        withAnimation {
            viewContext.delete(expense)
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete expense: \(error)")
            }
        }
    }

    // Optional sheet presentation state and helper
    @State private var editSheetExpenseID: NSManagedObjectID? = nil
    @State private var isEditSheetPresented: Bool = false

    private func openEditSheet(for expense: ExpenseEntity) {
        editSheetExpenseID = expense.objectID
        isEditSheetPresented = true
    }
}
