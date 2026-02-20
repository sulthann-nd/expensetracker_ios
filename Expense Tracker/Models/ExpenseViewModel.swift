//
//  ExpenseViewModel.swift
//  Expense Tracker
//
//  Created by Sulthan Navadeep on 09/02/26.
//


import Foundation
import CoreData
import Combine

final class ExpenseViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    @Published var lastSavedID: NSManagedObjectID?

    init(context: NSManagedObjectContext) {
        self.context = context
    }
 
    func saveExpense(amount: Double,
                     category: String?,
                     date: Date,
                     paymentMethod: String?,
                     note: String?,
                     currency: String? = "INR") throws -> NSManagedObjectID {
        let expense = ExpenseEntity(context: context)
        expense.id = UUID()
        expense.amount = amount
        expense.category = category
        expense.date = date
        expense.paymentMethod = paymentMethod
        expense.note = note
        expense.currency = currency
        try context.save()
        lastSavedID = expense.objectID
        return expense.objectID
    }

    func updateExpense(_ expense: ExpenseEntity,
                       amount: Double,
                       category: String?,
                       date: Date,
                       paymentMethod: String?,
                       note: String?,
                       currency: String?) throws {
        expense.amount = amount
        expense.category = category
        expense.date = date
        expense.paymentMethod = paymentMethod
        expense.note = note
        expense.currency = currency
        try context.save()
    }

    func deleteExpense(_ expense: ExpenseEntity) throws {
        context.delete(expense)
        try context.save()
    }
}
