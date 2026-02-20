//
//  CurrencyConverter.swift
//  Expense Tracker
//
//  Created by Assistant on 20/02/26.
//

import Foundation

class CurrencyConverter {
    /**
     Converts an amount from one currency to another using the provided exchange rates.
     Uses EUR as the base currency for conversion.

     - Parameters:
       - from: The source currency code (e.g., "USD", "EUR", "INR")
       - to: The target currency code (e.g., "USD", "EUR", "INR")
       - amount: The amount to convert
       - rates: Dictionary of exchange rates relative to EUR
     - Returns: The converted amount, or the original amount if conversion fails
     */
    static func convert(from: String, to: String, amount: Double, rates: [String: Double]?) -> Double {
        if from == to || rates == nil {
            return amount
        }

        // Get the rates for source and target currencies
        guard let fromRate = rates?[from], let toRate = rates?[to] else {
            return amount
        }

        // Convert: amount in 'from' currency -> EUR -> 'to' currency
        let amountInEur = amount / fromRate
        return amountInEur * toRate
    }

    /**
     Converts an amount to INR using the provided exchange rates.

     - Parameters:
       - from: The source currency code
       - amount: The amount to convert
       - rates: Dictionary of exchange rates relative to EUR
     - Returns: The amount converted to INR, or the original amount if conversion fails
     */
    static func convertToINR(from: String, amount: Double, rates: [String: Double]?) -> Double {
        return convert(from: from, to: "INR", amount: amount, rates: rates)
    }
}