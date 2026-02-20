//
//  ExchangeRateView.swift
//  Expense Tracker
//
//  Created by Sulthan Navadeep on 19/02/26.
//

import SwiftUI

struct ExchangeRateView: View {
    @StateObject private var viewModel = ExchangeRateViewModel()
    @State private var selectedTab = 0
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Exchange Rate Tools", selection: $selectedTab) {
                    Text("Converter").tag(0)
                    Text("Latest Rates").tag(1)
                    Text("Historical").tag(2)
                    Text("Symbols").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case 0:
                        CurrencyConverterTab(viewModel: viewModel)
                    case 1:
                        LatestRatesTab(viewModel: viewModel, searchText: $searchText)
                    case 2:
                        HistoricalRatesTab(viewModel: viewModel, searchText: $searchText)
                    case 3:
                        CurrencySymbolsTab(viewModel: viewModel, searchText: $searchText)
                    default:
                        CurrencyConverterTab(viewModel: viewModel)
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("Exchange Rates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        viewModel.refreshAllData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                viewModel.loadInitialData()
            }
        }
    }
}

// MARK: - Currency Converter Tab
struct CurrencyConverterTab: View {
    @ObservedObject var viewModel: ExchangeRateViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Amount Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount")
                        .font(.headline)
                    TextField("Enter amount", text: $viewModel.amount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                }

                // From Currency
                VStack(alignment: .leading, spacing: 8) {
                    Text("From Currency")
                        .font(.headline)
                    Picker("From Currency", selection: $viewModel.fromCurrency) {
                        ForEach(viewModel.currencySymbols) { symbol in
                            Text("\(symbol.code) - \(symbol.name)").tag(symbol.code)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                // To Currency
                VStack(alignment: .leading, spacing: 8) {
                    Text("To Currency")
                        .font(.headline)
                    Picker("To Currency", selection: $viewModel.toCurrency) {
                        ForEach(viewModel.currencySymbols) { symbol in
                            Text("\(symbol.code) - \(symbol.name)").tag(symbol.code)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                // Convert Button
                Button(action: {
                    viewModel.convertCurrency()
                }) {
                    Text("Convert")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                // Result
                if let result = viewModel.conversionResult {
                    VStack(spacing: 8) {
                        Text("Result")
                            .font(.headline)
                        Text("\(viewModel.amount) \(viewModel.fromCurrency) = \(String(format: "%.2f", result)) \(viewModel.toCurrency)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Loading/Error States
                switch viewModel.conversionState {
                case .loading:
                    ProgressView("Converting...")
                case .error(let message):
                    Text("Error: \(message)")
                        .foregroundColor(.red)
                        .padding()
                default:
                    EmptyView()
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Latest Rates Tab
struct LatestRatesTab: View {
    @ObservedObject var viewModel: ExchangeRateViewModel
    @Binding var searchText: String

    var body: some View {
        VStack {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search currencies...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)

            // Rates List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.getFilteredRates(searchText: searchText)) { rate in
                        HStack {
                            Text(rate.currency)
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%.4f", rate.rate))
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }

            // Loading/Error States
            switch viewModel.viewState {
            case .loading:
                if viewModel.hasLoadedLatestRates {
                    HStack {
                        ProgressView()
                        Text("Refreshing rates...")
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    ProgressView("Loading rates...")
                        .padding()
                }
            case .error(let message):
                Text("Error: \(message)")
                    .foregroundColor(.red)
                    .padding()
            default:
                if viewModel.latestRates.isEmpty && !viewModel.hasLoadedLatestRates {
                    Text("Tap refresh to load rates")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    EmptyView()
                }
            }
        }
    }
}

// MARK: - Historical Rates Tab
struct HistoricalRatesTab: View {
    @ObservedObject var viewModel: ExchangeRateViewModel
    @Binding var searchText: String

    var body: some View {
        VStack {
            // Date Picker
            DatePicker("Select Date", selection: $viewModel.selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding(.horizontal)
                .padding(.top)

            // Currency Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Currency")
                    .font(.headline)
                Picker("Currency", selection: $viewModel.selectedHistoricalCurrency) {
                    ForEach(viewModel.currencySymbols) { symbol in
                        Text("\(symbol.code) - \(symbol.name)").tag(symbol.code)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .padding(.horizontal)

            // Fetch Button
            Button(action: {
                viewModel.loadHistoricalRates()
            }) {
                Text("Fetch Historical Rates")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search currencies...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)

            // Rates List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.getFilteredHistoricalRates(searchText: searchText)) { rate in
                        HStack {
                            Text(rate.currency)
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%.4f", rate.rate))
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }

            // Loading/Error States
            switch viewModel.historicalState {
            case .loading:
                if viewModel.hasLoadedHistoricalRates {
                    HStack {
                        ProgressView()
                        Text("Loading new date...")
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    ProgressView("Loading historical rates...")
                        .padding()
                }
            case .error(let message):
                Text("Error: \(message)")
                    .foregroundColor(.red)
                    .padding()
            default:
                if viewModel.historicalRates.isEmpty && !viewModel.hasLoadedHistoricalRates {
                    Text("Select a date to load historical rates")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    EmptyView()
                }
            }
        }
    }
}

// MARK: - Currency Symbols Tab
struct CurrencySymbolsTab: View {
    @ObservedObject var viewModel: ExchangeRateViewModel
    @Binding var searchText: String

    var body: some View {
        VStack {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search currencies...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)

            // Symbols List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.getFilteredSymbols(searchText: searchText)) { symbol in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(symbol.code)
                                .font(.headline)
                            Text(symbol.name)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }

            // Loading/Error States
            switch viewModel.symbolsState {
            case .loading:
                if viewModel.hasLoadedSymbols {
                    HStack {
                        ProgressView()
                        Text("Refreshing symbols...")
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    ProgressView("Loading symbols...")
                        .padding()
                }
            case .error(let message):
                Text("Error: \(message)")
                    .foregroundColor(.red)
                    .padding()
            default:
                if viewModel.currencySymbols.isEmpty && !viewModel.hasLoadedSymbols {
                    Text("Tap refresh to load symbols")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    EmptyView()
                }
            }
        }
    }
}

struct ExchangeRateView_Previews: PreviewProvider {
    static var previews: some View {
        ExchangeRateView()
    }
}