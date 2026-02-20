//
//  Utiles.swift
//  Expense Tracker
//
//  Created by Sulthan Navadeep on 10/02/26.
//

import SwiftUI

struct CustomDivider: View {
    var body: some View {
        Rectangle()
            .fill(.gray.opacity(0.3))
            .frame(height: 1)
    }
}

struct AmountField: View {
    @Binding var amount: Double
    let maxAmount: Double
 
    var body: some View {
        HStack {
            Text("Amount")
                .font(.title2).bold()
            Spacer()
            TextField("0", value: $amount, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.title2)
                .bold()
                .onChange(of: amount) { oldValue, newValue in
                    if newValue > maxAmount {
                        amount = maxAmount
                    }
                }
        }
        .padding(.bottom)
    }
}

struct CategoryPicker: View {
    @Binding var selectedCategory: String
    let categories: [String]

    var body: some View {
        HStack {
            Text("Category")
                .bold()
            Spacer()

            Menu {
                ForEach(categories, id: \.self) { category in
                    Button(category) { selectedCategory = category }
                }
            } label: {
                HStack {
                    Text(selectedCategory)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding(.vertical)
        .font(.title2)
    }
}

struct DateRow: View {
    @Binding var date: Date
    let label: String

    var body: some View {
        HStack {
            Text(label).bold()
            Spacer()
            ZStack(alignment: .trailing) {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .opacity(0.011) // keeps it accessible but invisible
                    .id(date)

                HStack(spacing: 8) {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .foregroundStyle(.black)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                        .opacity(0.5)
                }
                .allowsHitTesting(false)
            }
        }
        .padding(.vertical)
        .font(.title2)
    }
}

struct PaymentMethodPicker: View {
    @Binding var paymentMethod: String?

    var body: some View {
        HStack {
            Text("Payment Method").bold()
            Spacer()
            Menu {
                Button("None") { paymentMethod = nil }
                Button("Cash") { paymentMethod = "Cash" }
                Button("Card") { paymentMethod = "Card" }
                Button("UPI") { paymentMethod = "UPI" }
            } label: {
                HStack(spacing: 6) {
                    Text(paymentMethod ?? "Cash")
                        .foregroundStyle(.black)
                        .bold()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding(.vertical)
        .font(.title2)
    }
}

struct NoteRow: View {
    @Binding var note: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("Note")
            Spacer()
            TextField("Optional", text: $note, axis: .vertical)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.plain)
                .font(.title2)
        }
        .padding(.top)
        .padding(.bottom)
        .font(.title2)
    }
}

