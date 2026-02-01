//
//  TransactionHistoryView.swift
//  CoinFlip
//
//  Created on Sprint 18 - App Store Readiness
//  Complete transaction history with filtering
//

import SwiftUI

struct TransactionHistoryView: View {
    let transactions: [Transaction]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: TransactionFilter = .all

    enum TransactionFilter: String, CaseIterable {
        case all = "All"
        case buy = "Buys"
        case sell = "Sells"
    }

    var filteredTransactions: [Transaction] {
        switch selectedFilter {
        case .all:
            return transactions
        case .buy:
            return transactions.filter { $0.type == .buy }
        case .sell:
            return transactions.filter { $0.type == .sell }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Filter Picker
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(TransactionFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)

                    // Transactions List
                    if filteredTransactions.isEmpty {
                        EmptyTransactionsView(filter: selectedFilter)
                    } else {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("\(filteredTransactions.count) Transaction\(filteredTransactions.count == 1 ? "" : "s")")
                                .font(.labelMedium)
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, Spacing.md)

                            ForEach(filteredTransactions) { transaction in
                                TransactionRow(transaction: transaction)
                                    .padding(.horizontal, Spacing.md)
                            }
                        }
                    }
                }
                .padding(.bottom, Spacing.xxl)
            }
            .background(Color.appBackground)
            .navigationTitle("Transaction History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primaryGreen)
                }
            }
        }
    }
}

// MARK: - Empty State

private struct EmptyTransactionsView: View {
    let filter: TransactionHistoryView.TransactionFilter

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.textSecondary)

            VStack(spacing: Spacing.sm) {
                Text("No \(filter.rawValue)")
                    .font(.headline2)
                    .foregroundColor(.textPrimary)

                Text(emptyMessage)
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private var emptyMessage: String {
        switch filter {
        case .all:
            return "You haven't made any trades yet. Start by buying some coins!"
        case .buy:
            return "You haven't purchased any coins yet. Browse trending coins to get started."
        case .sell:
            return "You haven't sold any coins yet. Sell from your portfolio when you're ready."
        }
    }
}

// MARK: - Preview

#Preview {
    TransactionHistoryView(transactions: [
        Transaction(
            portfolioId: UUID(),
            coin: MockData.featuredCoin,
            type: .buy,
            quantity: 100
        ),
        Transaction(
            portfolioId: UUID(),
            coin: MockData.featuredCoin,
            type: .sell,
            quantity: 50
        )
    ])
}
