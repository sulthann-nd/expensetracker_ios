//
//  ExchangeRateModels.swift
//  Expense Tracker
//
//  Created by Sulthan Navadeep on 19/02/26.
//

import Foundation

// MARK: - API Response Models
struct ExchangeRateResponse: Codable {
    let success: Bool
    let timestamp: Int?
    let base: String?
    let date: String?
    let rates: [String: Double]?
    let error: ExchangeRateError?

    enum CodingKeys: String, CodingKey {
        case success, timestamp, base, date, rates, error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        timestamp = try container.decodeIfPresent(Int.self, forKey: .timestamp)
        base = try container.decodeIfPresent(String.self, forKey: .base)
        date = try container.decodeIfPresent(String.self, forKey: .date)
        rates = try container.decodeIfPresent([String: Double].self, forKey: .rates)
        error = try container.decodeIfPresent(ExchangeRateError.self, forKey: .error)
    }
}

struct SymbolsResponse: Codable {
    let success: Bool
    let symbols: [String: String]?
    let error: ExchangeRateError?

    enum CodingKeys: String, CodingKey {
        case success, symbols, error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        symbols = try container.decodeIfPresent([String: String].self, forKey: .symbols)
        error = try container.decodeIfPresent(ExchangeRateError.self, forKey: .error)
    }
}

struct ConversionResponse: Codable {
    let success: Bool
    let query: ConversionQuery?
    let info: ConversionInfo?
    let date: String?
    let result: Double?
    let error: ExchangeRateError?

    enum CodingKeys: String, CodingKey {
        case success, query, info, date, result, error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        query = try container.decodeIfPresent(ConversionQuery.self, forKey: .query)
        info = try container.decodeIfPresent(ConversionInfo.self, forKey: .info)
        date = try container.decodeIfPresent(String.self, forKey: .date)
        result = try container.decodeIfPresent(Double.self, forKey: .result)
        error = try container.decodeIfPresent(ExchangeRateError.self, forKey: .error)
    }
}

struct ConversionQuery: Codable {
    let from: String
    let to: String
    let amount: Double
}

struct ConversionInfo: Codable {
    let timestamp: Int
    let rate: Double
}

struct ExchangeRateError: Codable {
    let code: Int
    let type: String
    let info: String
}

// MARK: - UI Models
struct CurrencySymbol: Identifiable {
    let id = UUID()
    let code: String
    let name: String
}

struct ExchangeRate: Identifiable {
    let id = UUID()
    let currency: String
    let rate: Double
    let symbol: String?
}

// MARK: - View States
enum ExchangeRateViewState {
    case idle
    case loading
    case success
    case error(String)
}