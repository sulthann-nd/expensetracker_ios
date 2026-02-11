import Foundation
import CoreData

final class ExpenseDataService {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    var canSaveToCoreData: Bool {
        context.persistentStoreCoordinator?.managedObjectModel.entitiesByName["Expense"] != nil
    }
 
    func saveExpense(amount: Double,
                     category: String,
                     date: Date,
                     paymentMethod: String?,
                     note: String?) throws {
        guard canSaveToCoreData,
              let entity = NSEntityDescription.entity(forEntityName: "Expense", in: context) else {
            throw NSError(domain: "ExpenseDataService",
                          code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Expense entity not found in Core Data model."])
        }

        let obj = NSManagedObject(entity: entity, insertInto: context)
        obj.setValue(amount, forKey: "amount")
        obj.setValue(category, forKey: "category")
        obj.setValue(date, forKey: "date")
        obj.setValue(paymentMethod, forKey: "paymentMethod")
        obj.setValue(note, forKey: "note")

        try context.save()
    }
}
