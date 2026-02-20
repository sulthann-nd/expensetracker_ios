import SwiftUI
import CoreData

struct AddExpenseView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount: Double = 0.0
    private let maxAmount: Double = 1e9
    @State private var selectedCategory: String = "Food"
    @State private var paymentMethod: String? = "Cash"
    @State private var date: Date = Date()
    @State private var note: String = ""
    @State private var selectedCurrency: String = "INR"

    @AppStorage("add_amount") private var storedAmount: Double = 0
    @AppStorage("add_category") private var storedCategory: String = "Food"
    @AppStorage("add_date") private var storedDate: Double = Date().timeIntervalSince1970
    @AppStorage("add_payment") private var storedPayment: String = "Cash"
    @AppStorage("add_note") private var storedNote: String = ""
    @AppStorage("add_currency") private var storedCurrency: String = "INR"

    // New state for alerts
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var isSuccess: Bool = false

    @StateObject private var vm: ExpenseViewModel
    @StateObject private var exchangeRateVM = ExchangeRateViewModel()
    
    init(context: NSManagedObjectContext? = nil) {
        let ctx = context ?? PersistenceController.shared.container.viewContext
        _vm = StateObject(wrappedValue: ExpenseViewModel(context: ctx))
    }

    private func saveExpenseAction() {
        guard amount > 0 else {
            alertTitle = "Invalid amount"
            alertMessage = "Please enter an amount greater than zero."
            showAlert = true
            return
        }
        do {
            _ = try vm.saveExpense(amount: amount,
                                             category: selectedCategory,
                                             date: date,
                                             paymentMethod: paymentMethod,
                                             note: (note == "Optional") ? nil : note,
                                             currency: selectedCurrency)
            alertTitle = "Saved"
            alertMessage = "Expense saved successfully."
            isSuccess = true
            // you can store savedID if you want to open Edit directly
            resetFormAfterSave()
        } catch {
            alertTitle = "Save Failed"
            alertMessage = error.localizedDescription
            isSuccess = false
        }
        showAlert = true
    }


    private func resetFormAfterSave() {
        // Lightweight reset — adjust to your UX needs
        amount = 0.0
        selectedCategory = "Food"
        date = Date()
        paymentMethod = nil
        note = "Optional"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()
            VStack(alignment: .center, spacing: 0) {
                Rectangle()
                    .fill(.gray.opacity(0.6))
                    .frame(height: 1)
                    .frame(maxWidth: .greatestFiniteMagnitude)
                    .padding(.horizontal, -16)

                ScrollView {
                    VStack {
                        AmountField(amount: $amount, maxAmount: 1e9)

                        CustomDivider()

                        CurrencyPicker(selectedCurrency: $selectedCurrency, currencies: exchangeRateVM.currencySymbols)

                        CustomDivider()

                        CategoryPicker(
                            selectedCategory: $selectedCategory,
                            categories: ["Food", "Transport", "Shopping", "Entertainment", "Bills", "Others"]
                        )

                        CustomDivider()

                        DateRow(date: $date, label: "Date")

                        CustomDivider()

                        PaymentMethodPicker(paymentMethod: $paymentMethod)

                        CustomDivider()

                        NoteRow(note: $note)

                        CustomDivider()
                    }
                    .padding()
                }
                .onAppear {
                    amount = storedAmount
                    selectedCategory = storedCategory
                    selectedCurrency = storedCurrency
                    date = Date(timeIntervalSince1970: storedDate)
                    paymentMethod = storedPayment
                    if storedNote.isEmpty {
                        note = "Optional"
                    } else {
                        note = storedNote
                    }
                    // Load currency symbols
                    exchangeRateVM.loadSymbols()
                }
                Spacer()
            }
            .padding()

            HStack(spacing: 12) {
                Button(role: .destructive) {
                    
                    resetFormAfterSave()
//                    // close the fullScreenCover and return to the dashboard
//                    dismiss()
                } label: {
                    Text("Reset")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .foregroundStyle(.black)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
                }

                Button {
                    
                    saveExpenseAction()
                    
                } label: {
                    Text("Save")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.blue)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color(.systemGray6))
            .ignoresSafeArea(edges: .bottom)
        }
        // Present an alert for success / failure
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
