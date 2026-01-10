import SwiftUI

struct SparklineView: View {
    let data: [Double]
    var lineColor: Color = .primaryGreen
    var lineWidth: CGFloat = 2

    private var isPositive: Bool {
        guard let first = data.first, let last = data.last else { return true }
        return last >= first
    }

    private var color: Color {
        lineColor == .primaryGreen ? (isPositive ? .gainGreen : .lossRed) : lineColor
    }

    var body: some View {
        GeometryReader { geometry in
            if data.count > 1 {
                let width = geometry.size.width
                let height = geometry.size.height
                let minVal = data.min() ?? 0
                let maxVal = data.max() ?? 1
                let range = maxVal - minVal

                Path { path in
                    let stepX = width / CGFloat(data.count - 1)
                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalizedY = range > 0 ? (value - minVal) / range : 0.5
                        let y = height - (CGFloat(normalizedY) * height * 0.9) - (height * 0.05)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SparklineView(data: [10, 12, 11, 15, 14, 18, 22, 20, 25])
            .frame(height: 50)
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)

        SparklineView(data: [25, 22, 24, 18, 20, 15, 12, 14, 10])
            .frame(height: 50)
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
    }
    .padding()
    .background(Color.appBackground)
}
