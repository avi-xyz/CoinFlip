import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var showOnboarding: Bool

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack {
                // Skip Button
                HStack {
                    Spacer()
                    if viewModel.currentPage < viewModel.pages.count - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                        .padding()
                    }
                }

                // Pages
                TabView(selection: $viewModel.currentPage) {
                    ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPage(
                            emoji: page.emoji,
                            title: page.title,
                            subtitle: page.subtitle
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                // Bottom Actions
                VStack(spacing: Spacing.md) {
                    if viewModel.currentPage == viewModel.pages.count - 1 {
                        PrimaryButton(title: "Get Started") {
                            completeOnboarding()
                        }
                    } else {
                        SecondaryButton(title: "Next") {
                            withAnimation {
                                viewModel.nextPage()
                            }
                        }
                    }

                    // Page Indicators (Custom)
                    HStack(spacing: Spacing.sm) {
                        ForEach(0..<viewModel.pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == viewModel.currentPage ? Color.primaryGreen : Color.textMuted)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.bottom, Spacing.lg)
                }
                .padding(.horizontal, Spacing.xl)
            }
        }
    }

    private func completeOnboarding() {
        HapticManager.shared.success()
        withAnimation {
            showOnboarding = false
        }
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
}
