//
//  OnboardingView.swift
//  Expense Tracker
//
//  Created by Sulthan Navadeep on 29/01/26.
//

import SwiftUI
 
struct OnboardingView: View {
    @Binding var currentStep: Int
    
    var body: some View {
        ZStack {
            // Background Gradient to match the blue theme
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "2B72D1"), Color(hex: "1A5BB5")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                // 1. Header Text
                VStack(spacing: 8) {
                    Text("Welcome to")
                        .font(.system(size: 28, weight: .bold))
                    Text("Expense Tracker")
                        .font(.system(size: 32, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.top, 50)

                // 2. Central Image (Your uploaded asset)
                Image("wallet_illustration") // Replace with your image name in Assets
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
                    .padding(.vertical, 20)

                // 3. Feature List
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(title: "Track Your Spending")
                    FeatureRow(title: "Categorize Expenses")
                    FeatureRow(title: "Gain Insights")
                }
                .padding(.horizontal, 40)

                Spacer()

                // 4. Primary "Get Started" Button
                Button(action: {
                    currentStep = 1
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }
                .padding(.horizontal, 40)
                
            }
        }
    }
}

#Preview("OnboardingView") {
    OnboardingView(currentStep: .constant(0))
}

// Helper view for the list items
struct FeatureRow: View {
    let title: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
            Spacer()
        }
    }
}

// Hex color extension for precise design matching
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}



struct FinancialGoalsView: View {
    @State private var selectedCurrency = "USD ($)"
    @State private var monthlyLimit: Double = 1500
    @Binding var currentStep: Int
    
    var body: some View {
        ZStack {
            // Background Gradient consistent with the onboarding theme
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "2B72D1"), Color(hex: "1A5BB5")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {
                // 1. Header
                Text("Set Your\nFinancial Goals")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.top, 40)

                // 2. Central Image (The Piggy Bank Illustration)
                Image("savings_piggy") // Replace with your asset name
                    .resizable()
                    .scaledToFit()
                    .frame(height: 220)
                    .padding(.vertical, 10)

                // 3. Input Section
                VStack(alignment: .leading, spacing: 20) {
                    // Currency Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Base Currency")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack {
                            Image(systemName: "flag.fill") // Placeholder for flag icon
                            Text(selectedCurrency)
                            Spacer()
                            Image(systemName: "chevron.down")
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .foregroundColor(.black)
                    }

                    // Spending Limit Slider
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Monthly Spending Limit")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Slider(value: $monthlyLimit, in: 0...5000, step: 100)
                            .accentColor(.orange)
                        
                        HStack {
                            Text("$0").font(.caption)
                            Spacer()
                            Text("$5,000+").font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.7))
                        
                        Text("$\(Int(monthlyLimit), format: .number)")
                            .font(.system(size: 36, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 30)

                Spacer()

                // 4. Continue Button
                Button(action: {
                    currentStep = 2
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.orange)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 30)
            }
        }
    }
}

#Preview("FinancialGoalsView") {
    FinancialGoalsView(currentStep: .constant(1))
}

import SwiftUI

struct PrimarygoalsView: View {
    @Binding var isFinished: Bool
    @Binding var selectedTab: Int
    @Binding var currentStep: Int
    
    var body: some View {
        ZStack {
            // 1. Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "3A7BD5"), Color(hex: "0052D4")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 2. Header
                Text("Primary Goals")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 50)

                Spacer()

                // 3. The Main Image (Your uploaded graphic)
                // Replace "OnboardingGraphics" with the name of your file in Assets.xcassets
                Image("OnboardingGraphics")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 30)

                Spacer()

                // 4. Checklist Section
                VStack(alignment: .leading, spacing: 18) {
                    FeatureRow(title: "Log expenses in seconds")
                    FeatureRow(title: "Understand your money better")
                    FeatureRow(title: "Reliable anytime, anywhere")
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)

                // 5. Get Started Button
                Button(action: {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    selectedTab = 0
                    isFinished = true
                }) {
                    Text("Get Started")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.orange, .yellow]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
    }
}

