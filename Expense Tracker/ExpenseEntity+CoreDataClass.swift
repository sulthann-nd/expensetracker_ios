//
//  ExpenseEntity.swift
//  Expense Tracker
//
//  Created by Sulthan Navadeep on 09/02/26.
//


import Foundation
import CoreData

@objc(ExpenseEntity)
public class ExpenseEntity: NSManagedObject {}
 
extension ExpenseEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExpenseEntity> {
        return NSFetchRequest<ExpenseEntity>(entityName: "ExpenseEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var amount: Double
    @NSManaged public var category: String?
    @NSManaged public var date: Date?
    @NSManaged public var paymentMethod: String?
    @NSManaged public var note: String?
}
