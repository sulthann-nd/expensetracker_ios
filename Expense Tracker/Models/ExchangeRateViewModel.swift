//
//  ExchangeRateViewModel.swift
//  Expense Tracker
//
//  Created by Sulthan Navadeep on 19/02/26.
//

import Foundation
import Combine

/**
 Optimized Exchange Rate ViewModel with smart data loading:
 
 - Constant data (symbols, latest rates): Loaded once when view appears
 - Historical data: Loaded when date changes, cached until date changes
 - Conversion: On-demand loading when convert button is pressed
 - Refresh: Manual refresh available for all data
 */
class ExchangeRateViewModel: ObservableObject {
    @Published var latestRates: [ExchangeRate] = [] {
        didSet {
            saveLatestRates()
        }
    }
    @Published var currencySymbols: [CurrencySymbol] = [] {
        didSet {
            saveCurrencySymbols()
        }
    }
    @Published var conversionResult: Double?
    @Published var selectedDate = Date() {
        didSet {
            // Reload historical rates when date changes
            if !Calendar.current.isDate(selectedDate, inSameDayAs: lastSelectedDate) {
                lastSelectedDate = selectedDate
                hasLoadedHistoricalRates = false
                loadHistoricalRates()
            }
        }
    }
    @Published var historicalRates: [ExchangeRate] = []

    // UI State
    @Published var viewState: ExchangeRateViewState = .idle
    @Published var conversionState: ExchangeRateViewState = .idle
    @Published var symbolsState: ExchangeRateViewState = .idle
    @Published var historicalState: ExchangeRateViewState = .idle

    // Form inputs
    @Published var fromCurrency = "EUR"
    @Published var toCurrency = "USD"
    @Published var amount: String = "1.0"
    @Published var selectedHistoricalCurrency = "USD" {
        didSet {
            // Reload historical rates when currency changes
            if oldValue != selectedHistoricalCurrency && hasLoadedHistoricalRates {
                loadHistoricalRates()
            }
        }
    }

    // Data loading flags
    private(set) var hasLoadedSymbols = false
    private(set) var hasLoadedLatestRates = false
    private(set) var hasLoadedHistoricalRates = false

    private let service = ExchangeRateService()
    private var cancellables = Set<AnyCancellable>()
    private let latestRatesKey = "latestExchangeRates"
    private let currencySymbolsKey = "currencySymbols"
    private var lastSelectedDate = Date()
    
    init() {
        // Store initial date
        lastSelectedDate = selectedDate
        loadPersistedData()
    }
    
    private func loadPersistedData() {
        loadPersistedLatestRates()
        loadCurrencySymbols()
    }
    
    private func saveLatestRates() {
        let ratesDict = Dictionary(uniqueKeysWithValues: latestRates.map { ($0.currency, $0.rate) })
        UserDefaults.standard.set(ratesDict, forKey: latestRatesKey)
    }
    
    private func loadPersistedLatestRates() {
        if let ratesDict = UserDefaults.standard.dictionary(forKey: latestRatesKey) as? [String: Double] {
            latestRates = ratesDict.map { ExchangeRate(currency: $0.key, rate: $0.value, symbol: nil) }
                .sorted { $0.currency < $1.currency }
        }
    }
    
    private func saveCurrencySymbols() {
        let symbolsDict = Dictionary(uniqueKeysWithValues: currencySymbols.map { ($0.code, $0.name) })
        UserDefaults.standard.set(symbolsDict, forKey: currencySymbolsKey)
    }
    
    private func loadCurrencySymbols() {
        if let symbolsDict = UserDefaults.standard.dictionary(forKey: currencySymbolsKey) as? [String: String] {
            currencySymbols = symbolsDict.map { CurrencySymbol(code: $0.key, name: $0.value) }
                .sorted { $0.code < $1.code }
        }
    }

    // Load initial data when view appears
    func loadInitialData() {
        if !hasLoadedSymbols {
            loadSymbols()
        }
        if !hasLoadedLatestRates {
            loadLatestRates()
        }
        if !hasLoadedHistoricalRates {
            loadHistoricalRates()
        }
    }

    // Refresh all data (useful for manual refresh)
    func refreshAllData() {
        hasLoadedSymbols = false
        hasLoadedLatestRates = false
        hasLoadedHistoricalRates = false
        loadInitialData()
    }

    // Refresh only latest rates (useful for periodic updates)
    func refreshLatestRates() {
        hasLoadedLatestRates = false
        loadLatestRates()
    }

    // Check if initial data is loaded
    var isInitialDataLoaded: Bool {
        hasLoadedSymbols && hasLoadedLatestRates
    }

    // Check if historical data is loaded
    var isHistoricalDataLoaded: Bool {
        hasLoadedHistoricalRates
    }

    func loadLatestRates() {
        // If we already have rates loaded (from persistence), don't fetch again
        if !latestRates.isEmpty {
            hasLoadedLatestRates = true
            return
        }
        
        viewState = .loading

        service.fetchLatestRates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    self?.viewState = .success
                case .failure(let error):
                    // Check if it's an ATS error and provide helpful message
                    if error.localizedDescription.contains("App Transport Security") ||
                       error.localizedDescription.contains("cleartext HTTP") {
                        self?.viewState = .error("Network configuration required. Please configure App Transport Security in Xcode as described in README.md")
                    } else {
                        self?.viewState = .error(error.localizedDescription)
                    }
                }
            } receiveValue: { [weak self] response in
                if response.success, let rates = response.rates {
                    self?.latestRates = rates.map { ExchangeRate(currency: $0.key, rate: $0.value, symbol: nil) }
                        .sorted { $0.currency < $1.currency }
                    self?.hasLoadedLatestRates = true
                }
            }
            .store(in: &cancellables)
    }

    func loadSymbols() {
        // If we already have symbols loaded (from persistence), don't fetch again
        if !currencySymbols.isEmpty {
            hasLoadedSymbols = true
            return
        }
        
        symbolsState = .loading

        service.fetchSymbols()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    self?.symbolsState = .success
                case .failure(let error):
                    if error.localizedDescription.contains("App Transport Security") ||
                       error.localizedDescription.contains("cleartext HTTP") {
                        self?.symbolsState = .error("Network configuration required. Please configure App Transport Security in Xcode as described in README.md")
                    } else {
                        self?.symbolsState = .error(error.localizedDescription)
                    }
                }
            } receiveValue: { [weak self] response in
                if response.success, let symbols = response.symbols {
                    self?.currencySymbols = symbols.map { CurrencySymbol(code: $0.key, name: $0.value) }
                        .sorted { $0.code < $1.code }
                    self?.hasLoadedSymbols = true
                }
            }
            .store(in: &cancellables)
    }

    func convertCurrency() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            conversionState = .error("Please enter a valid amount greater than 0")
            return
        }

        guard !fromCurrency.isEmpty && !toCurrency.isEmpty else {
            conversionState = .error("Please select both currencies")
            return
        }

        // Check if we have the latest rates loaded
        guard !latestRates.isEmpty else {
            conversionState = .error("Currency rates not available. Please wait for rates to load or refresh.")
            return
        }

        conversionState = .loading

        // Perform conversion using latest rates (free tier doesn't support convert API)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Find rates for both currencies
            let fromRate = self.fromCurrency == "EUR" ? 1.0 : self.latestRates.first(where: { $0.currency == self.fromCurrency })?.rate
            let toRate = self.toCurrency == "EUR" ? 1.0 : self.latestRates.first(where: { $0.currency == self.toCurrency })?.rate

            guard let fromRate = fromRate, let toRate = toRate else {
                DispatchQueue.main.async {
                    self.conversionState = .error("Exchange rate not available for selected currencies")
                }
                return
            }

            // Calculate conversion: amount in EUR = amount / fromRate, then convert to target = amountInEUR * toRate
            let amountInEUR = amountValue / fromRate
            let convertedAmount = amountInEUR * toRate

            DispatchQueue.main.async {
                self.conversionResult = convertedAmount
                self.conversionState = .success
            }
        }
    }

    func loadHistoricalRates() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)

        // Validate date is not in the future
        let today = Date()
        if selectedDate > today {
            historicalState = .error("Cannot select future dates")
            return
        }

        historicalState = .loading

        service.fetchHistoricalRates(date: dateString)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    self?.historicalState = .success
                case .failure(let error):
                    if error.localizedDescription.contains("App Transport Security") ||
                       error.localizedDescription.contains("cleartext HTTP") {
                        self?.historicalState = .error("Network configuration required. Please configure App Transport Security in Xcode as described in README.md")
                    } else {
                        self?.historicalState = .error(error.localizedDescription)
                    }
                }
            } receiveValue: { [weak self] response in
                if response.success, let rates = response.rates {
                    self?.historicalRates = rates.map { ExchangeRate(currency: $0.key, rate: $0.value, symbol: nil) }
                        .sorted { $0.currency < $1.currency }
                    self?.hasLoadedHistoricalRates = true
                } else if let error = response.error {
                    self?.historicalState = .error("API Error: \(error.info)")
                } else {
                    self?.historicalState = .error("Failed to load historical rates")
                }
            }
            .store(in: &cancellables)
    }

    func getFilteredRates(searchText: String) -> [ExchangeRate] {
        if searchText.isEmpty {
            return latestRates
        }
        return latestRates.filter { $0.currency.lowercased().contains(searchText.lowercased()) }
    }

    func getFilteredSymbols(searchText: String) -> [CurrencySymbol] {
        if searchText.isEmpty {
            return currencySymbols
        }
        return currencySymbols.filter {
            $0.code.lowercased().contains(searchText.lowercased()) ||
            $0.name.lowercased().contains(searchText.lowercased())
        }
    }

    func getFilteredHistoricalRates(searchText: String) -> [ExchangeRate] {
        if searchText.isEmpty {
            return historicalRates
        }
        return historicalRates.filter { $0.currency.lowercased().contains(searchText.lowercased()) }
    }

    // Computed property to get rates as dictionary for currency conversion
    var latestRatesDictionary: [String: Double] {
        var dict: [String: Double] = [:]
        for rate in latestRates {
            dict[rate.currency] = rate.rate
        }
        return dict
    }
}