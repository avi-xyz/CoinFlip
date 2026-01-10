import SwiftUI

struct LoadingSkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Featured Card Skeleton
            BaseCard {
                VStack(spacing: Spacing.md) {
                    HStack {
                        SkeletonBox(width: 60, height: 60)
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            SkeletonBox(width: 120, height: 20)
                            SkeletonBox(width: 80, height: 16)
                        }
                        Spacer()
                    }

                    SkeletonBox(width: nil, height: 80)

                    HStack(spacing: Spacing.md) {
                        SkeletonBox(width: nil, height: 50)
                        SkeletonBox(width: nil, height: 50)
                    }
                }
            }

            // Coin Cards Skeleton
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SkeletonBox(width: 180, height: 20)
                    .padding(.horizontal, Spacing.xs)

                ForEach(0..<5, id: \.self) { _ in
                    BaseCard {
                        HStack(spacing: Spacing.md) {
                            SkeletonBox(width: 50, height: 50)

                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                SkeletonBox(width: 100, height: 18)
                                SkeletonBox(width: 60, height: 14)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: Spacing.xs) {
                                SkeletonBox(width: 80, height: 18)
                                SkeletonBox(width: 60, height: 14)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SkeletonBox: View {
    let width: CGFloat?
    let height: CGFloat
    @State private var isAnimating = false

    var body: some View {
        Rectangle()
            .fill(Color.cardBackground)
            .frame(width: width, height: height)
            .cornerRadius(Spacing.sm)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cardBackground.opacity(0),
                                Color.textMuted.opacity(0.15),
                                Color.cardBackground.opacity(0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 200 : -200)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Spacing.sm))
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    LoadingSkeletonView()
        .padding()
        .background(Color.appBackground)
}
