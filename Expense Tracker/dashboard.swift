import SwiftUI
import CoreData

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isPresentingAdd: Bool = false

    // Fetch recent expenses sorted by date descending
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ExpenseEntity.date, ascending: false)],
        animation: .default
    ) private var expenses: FetchedResults<ExpenseEntity>

    // MARK: - Computed stats
    private var todaysSpending: Double {
        let calendar = Calendar.current
        return expenses.reduce(0) { acc, e in
            guard let date = e.date else { return acc }
            return calendar.isDateInToday(date) ? acc + e.amount : acc
        }
    }

    private var thisMonthSpending: Double {
        let calendar = Calendar.current
        let now = Date()
        return expenses.reduce(0) { acc, e in
            guard let date = e.date else { return acc }
            let sameMonth = calendar.component(.year, from: date) == calendar.component(.year, from: now)
                && calendar.component(.month, from: date) == calendar.component(.month, from: now)
            return sameMonth ? acc + e.amount : acc
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    header
                    statCards
                    addExpenseButton
                    recentExpenses
                }
                .padding(.bottom, 24)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        Analytics()
                            .navigationTitle("Analytics")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Image(systemName: "chart.pie.fill")
                    }
                }
            }
        }
    }

    // MARK: - UI Parts

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [Color.blue, Color.blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)

            VStack(alignment: .leading, spacing: 8) {
                Text("Dashboard")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text("Hello, User")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(20)
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var statCards: some View {
        HStack(spacing: 12) {
            StatCard(title: "Today's Spending", amount: todaysSpending)
            StatCard(title: "This Month", amount: thisMonthSpending)
        }
        .padding(.horizontal)
    }

    private var addExpenseButton: some View {
        Button {
            isPresentingAdd = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.white)
                Text("Add Expense")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.blue)
                    .shadow(color: .blue.opacity(0.30), radius: 14, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .fullScreenCover(isPresented: $isPresentingAdd) {
            NavigationStack {
                AddExpenseView()
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        // Centered title
                        ToolbarItem(placement: .principal) {
                            Text("Add Expense")
                                .font(.headline)
                                .bold()
                        }

                        // Close button on the leading side
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                isPresentingAdd = false
                            } label: {
                                Image(systemName: "xmark")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
            }
        }
    }

    private var recentExpenses: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Expenses")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 10) {
                if expenses.isEmpty {
                    Text("No expenses yet")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(expenses.prefix(10), id: \.objectID) { e in
                        ExpenseRowFromEntity(expenseEntity: e)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Subviews

private struct StatCard: View {
    let title: String
    let amount: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.title2.bold())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

private struct ExpenseRowFromEntity: View {
    @ObservedObject var expenseEntity: ExpenseEntity

        var body: some View {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(iconColor(for: expenseEntity.category).opacity(0.15))
                    Image(systemName: iconName(for: expenseEntity.category))
                        .foregroundStyle(iconColor(for: expenseEntity.category))
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(expenseEntity.note ?? (expenseEntity.category ?? "Expense"))
                        .font(.headline)
                    Text(expenseEntity.category ?? "Unknown")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
 
                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(expenseEntity.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.headline)
                    if let date = expenseEntity.date {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        }

    private func iconName(for category: String?) -> String {
        switch category {
        case "Shopping": return "cart.fill"
        case "Food": return "fork.knife"
        case "Transport": return "car.fill"
        case "Entertainment": return "film.fill"
        case "Bills": return "doc.text.fill"
        case "Others": return "square.grid.2x2"
        default: return "tag.fill"
        }
    }

    private func iconColor(for category: String?) -> Color {
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
