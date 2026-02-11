//
//  ContentView.swift
//  Expense Tracker
//
//  Created by Sulthan Navadeep on 28/01/26.
//

import SwiftUI
import CoreData

struct EditExpenseView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let expenseID: NSManagedObjectID?

    @State private var amount: Double = 0.0
    @State private var selectedCategory: String = "Food"
    @State private var date: Date = Date()
    @State private var paymentMethod: String? = nil
    @State private var note: String = ""

    @State private var showDeleteConfirmation = false

    let categories = ["Food", "Transport", "Shopping", "Entertainment", "Bills", "Others"]

    // MARK: - Lifecycle
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()

            VStack(alignment: .center, spacing: 12) {
                // Edge-to-edge solid line
                Rectangle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                ScrollView {
                    VStack(spacing: 0) {
                        // Amount
                        AmountField(amount: $amount, maxAmount: 10000)
                        CustomDivider()

                        // Category
                        CategoryPicker(selectedCategory: $selectedCategory, categories: categories)
                        CustomDivider()

                        // Date
                        DateRow(date: $date, label: "Date")
                        CustomDivider()

                        // Payment Method
                        PaymentMethodPicker(paymentMethod: $paymentMethod)
                        CustomDivider()

                        // Note
                        NoteRow(note: $note)
                    }
                    .padding()
                }

                Spacer()
            }
            .onAppear {
                loadExpenseIfNeeded()
            }
            .padding(16)

            // Bottom action bar
            HStack(spacing: 12) {
                // Delete button with confirmation
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Text("Delete")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.red)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
                }
                .alert("Delete Expense", isPresented: $showDeleteConfirmation) {
                    Button("Delete", role: .destructive) { performDelete() }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This will permanently remove the expense. Are you sure?")
                }

                // Save button
                Button {
                    saveEditedExpense()
                } label: {
                    Text("Save")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.blue)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color(.systemGray6))
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Data loading
    private func loadExpenseIfNeeded() {
        guard let id = expenseID else { return }
        do {
            if let expense = try viewContext.existingObject(with: id) as? ExpenseEntity {
                amount = expense.amount
                selectedCategory = expense.category ?? "Food"
                date = expense.date ?? Date()
                paymentMethod = expense.paymentMethod
                note = expense.note ?? ""
            }
        } catch {
            print("Failed to load expense: \(error)")
        }
    }

    // MARK: - Save
    private func saveEditedExpense() {
        do {
            if let id = expenseID,
               let expense = try viewContext.existingObject(with: id) as? ExpenseEntity {
                // Update existing expense
                expense.amount = amount
                expense.category = selectedCategory
                expense.date = date
                expense.paymentMethod = paymentMethod
                expense.note = note.isEmpty ? nil : note
            } else {
                // Create new expense
                let newExpense = ExpenseEntity(context: viewContext)
                newExpense.id = UUID()
                newExpense.amount = amount
                newExpense.category = selectedCategory
                newExpense.date = date
                newExpense.paymentMethod = paymentMethod
                newExpense.note = note.isEmpty ? nil : note
            }

            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to save edited expense: \(error)")
            viewContext.rollback()
        }
    }

    // MARK: - Delete
    private func performDelete() {
        guard let id = expenseID else {
            // nothing to delete; just dismiss
            dismiss()
            return
        }

        do {
            if let expense = try viewContext.existingObject(with: id) as? ExpenseEntity {
                try withAnimation {
                    viewContext.delete(expense)
                    try viewContext.save()
                    dismiss()
                }
            } else {
                // If object not found, just dismiss
                dismiss()
            }
        } catch {
            print("Failed to delete expense: \(error)")
            viewContext.rollback()
        }
    }
}


// MARK: - Binding helper
fileprivate extension Binding where Value == String? {
    init(_ source: Binding<String?>, replacingNilWith defaultValue: String) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { newValue in source.wrappedValue = ((newValue?.isEmpty) != nil) ? nil : newValue }
        )
    }
}
