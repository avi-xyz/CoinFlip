import SwiftUI

struct LeaderboardLoadingSkeleton: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // User Stats Skeleton
            BaseCard {
                VStack(spacing: Spacing.md) {
                    SkeletonBox(width: 100, height: 16)
                    SkeletonBox(width: 80, height: 48)

                    HStack(spacing: Spacing.xl) {
                        VStack(spacing: Spacing.xs) {
                            SkeletonBox(width: 60, height: 14)
                            SkeletonBox(width: 80, height: 20)
                        }

                        VStack(spacing: Spacing.xs) {
                            SkeletonBox(width: 60, height: 14)
                            SkeletonBox(width: 60, height: 20)
                        }
                    }
                }
                .padding(.vertical, Spacing.sm)
            }

            // Leaderboard Entries Skeleton
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SkeletonBox(width: 120, height: 20)
                    .padding(.horizontal, Spacing.xs)

                ForEach(0..<10, id: \.self) { _ in
                    BaseCard {
                        HStack(spacing: Spacing.md) {
                            // Rank
                            SkeletonBox(width: 40, height: 40)

                            // Avatar
                            SkeletonBox(width: 40, height: 40)

                            // Username
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                SkeletonBox(width: 100, height: 16)
                                SkeletonBox(width: 60, height: 14)
                            }

                            Spacer()

                            // Stats
                            VStack(alignment: .trailing, spacing: Spacing.xs) {
                                SkeletonBox(width: 80, height: 16)
                                SkeletonBox(width: 50, height: 14)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    LeaderboardLoadingSkeleton()
        .padding()
        .background(Color.appBackground)
}
