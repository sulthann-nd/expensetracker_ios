//
//  ExchangeRateService.swift
//  Expense Tracker
//
//  Created by Sulthan Navadeep on 19/02/26.
//

import Foundation
import Combine

class ExchangeRateService {
    private let baseURL = "http://api.exchangeratesapi.io/v1"
    // TODO: Replace with your actual API key from https://exchangeratesapi.io/
    private let accessKey = "3fbf307274f9f4213b74ae94a1d6ddee" // Replace with actual API key

    func fetchLatestRates() -> AnyPublisher<ExchangeRateResponse, Error> {
        let urlString = "\(baseURL)/latest?access_key=\(accessKey)"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: ExchangeRateResponse.self, decoder: JSONDecoder())
            .mapError { error in
                print("Latest rates decoding error: \(error)")
                return error
            }
            .eraseToAnyPublisher()
    }

    func fetchSymbols() -> AnyPublisher<SymbolsResponse, Error> {
        let urlString = "\(baseURL)/symbols?access_key=\(accessKey)"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: SymbolsResponse.self, decoder: JSONDecoder())
            .mapError { error in
                print("Symbols decoding error: \(error)")
                return error
            }
            .eraseToAnyPublisher()
    }

    func convertCurrency(from: String, to: String, amount: Double) -> AnyPublisher<ConversionResponse, Error> {
        let urlString = "\(baseURL)/convert?access_key=\(accessKey)&from=\(from)&to=\(to)&amount=\(amount)"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: ConversionResponse.self, decoder: JSONDecoder())
            .mapError { error in
                print("Conversion decoding error: \(error)")
                return error
            }
            .eraseToAnyPublisher()
    }

    func fetchHistoricalRates(date: String) -> AnyPublisher<ExchangeRateResponse, Error> {
        let urlString = "\(baseURL)/\(date)?access_key=\(accessKey)"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: ExchangeRateResponse.self, decoder: JSONDecoder())
            .mapError { error in
                print("Historical rates decoding error: \(error)")
                return error
            }
            .eraseToAnyPublisher()
    }
}
