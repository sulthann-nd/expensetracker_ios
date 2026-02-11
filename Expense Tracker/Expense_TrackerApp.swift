import SwiftUI
import CoreData

@main
struct Expense_TrackerApp: App {
    let persistenceController = PersistenceController.shared

    // Read synchronously at launch to avoid UI flicker/delay
    @State private var hasCompletedOnboardingState: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var selectedTab: Int = 0

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboardingState {
                    // Onboarding flow
                    OnboardingFlowContainer(
                        isFinished: $hasCompletedOnboardingState,
                        selectedTab: $selectedTab
                    )
                } else {
                    // Main App Flow with ExpenseList tab added
                    TabView(selection: $selectedTab) {
                        NavigationStack {
                            DashboardView()
                        }
                        .tabItem {
                            Label("Dashboard", systemImage: "house.fill")
                        }
                        .tag(0)

                        NavigationStack {
                            ExpenseListView()
                        }
                        .tabItem {
                            Label("List", systemImage: "list.bullet")
                        }
                        .tag(1)
                    }
                }
            }
            // Inject context for both branches immediately
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .onAppear {
                // Optional: ensure persistence controller has started loading stores.
                // If your PersistenceController does heavy work synchronously in init,
                // consider making that work asynchronous to avoid startup stalls.
            }
        }
    }
}

// MARK: - Onboarding Flow Container
struct OnboardingFlowContainer: View {
    @Binding var isFinished: Bool
    @Binding var selectedTab: Int
    @State private var currentStep = 0

    var body: some View {
        ZStack {
            // Swippable Onboarding Pages
            TabView(selection: $currentStep) {
                OnboardingView().tag(0)
                FinancialGoalsView().tag(1)
                PrimarygoalsView().tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .background(
                LinearGradient(colors: [Color(red: 0.29, green: 0.56, blue: 0.89), Color(red: 0.12, green: 0.35, blue: 0.69)],
                               startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            )
 
            // Skip Button Layer
            VStack {
                HStack {
                    Spacer()
                    Button("Skip") {
                        // Persist and switch immediately
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        selectedTab = 1
                        isFinished = true
                    }
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 50)
                    .padding(.trailing, 30)
                }
                Spacer()

                // Show Get Started only on the final page (PrimarygoalsView)
                if currentStep == 2 {
                    Button(action: {
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        selectedTab = 1
                        isFinished = true
                    }) {
                        Text("Get Started")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
                            )
                            .cornerRadius(12)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 60)
                    }
                }
            }
        }
    }
}
