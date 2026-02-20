//
//  CurrencyPicker.swift
//  Expense Tracker
//
//  Created by Assistant on 20/02/26.
//

import SwiftUI

struct CurrencyPicker: View {
    @Binding var selectedCurrency: String
    let currencies: [CurrencySymbol]

    var body: some View {
        HStack {
            Text("Currency")
                .bold()
            Spacer()

            Menu {
                ForEach(currencies.sorted { $0.code < $1.code }, id: \.code) { currency in
                    Button(action: {
                        selectedCurrency = currency.code
                    }) {
                        HStack {
                            Text(currency.code)
                                .fontWeight(.medium)
                            Text("(\(currency.name))")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selectedCurrency)
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

struct CurrencyPicker_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCurrencies = [
            CurrencySymbol(code: "INR", name: "Indian Rupee"),
            CurrencySymbol(code: "USD", name: "US Dollar"),
            CurrencySymbol(code: "EUR", name: "Euro")
        ]
        CurrencyPicker(selectedCurrency: .constant("INR"), currencies: sampleCurrencies)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}