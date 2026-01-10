import SwiftUI

struct ConfettiView: View {
    @State private var particles: [Particle] = []
    @State private var screenWidth: CGFloat = 400
    let colors: [Color] = [.primaryGreen, .primaryPurple, .yellow, .pink, .cyan]

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    for particle in particles {
                        let age = timeline.date.timeIntervalSince(particle.created)
                        guard age < particle.lifetime else { continue }
                        let progress = age / particle.lifetime
                        let x = particle.startX + particle.velocityX * age
                        let y = particle.startY + particle.velocityY * age + (400 * age * age)
                        let opacity = 1.0 - progress

                        context.opacity = opacity
                        let rect = CGRect(x: x - particle.size/2, y: y - particle.size/2, width: particle.size, height: particle.size)
                        context.fill(Path(ellipseIn: rect), with: .color(particle.color))
                    }
                }
            }
            .onAppear {
                screenWidth = geometry.size.width
                generateParticles()
            }
        }
        .allowsHitTesting(false)
    }

    private func generateParticles() {
        let width = screenWidth
        for _ in 0..<50 {
            particles.append(Particle(
                startX: width/2 + Double.random(in: -50...50),
                startY: 0,
                velocityX: Double.random(in: -150...150),
                velocityY: Double.random(in: -400...(-200)),
                size: Double.random(in: 8...16),
                color: colors.randomElement()!,
                lifetime: Double.random(in: 2...3),
                created: Date()
            ))
        }
    }

    struct Particle: Identifiable {
        let id = UUID()
        let startX, startY, velocityX, velocityY, size: Double
        let color: Color
        let lifetime: Double
        let created: Date
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        Text("🎉").font(.system(size: 64))
        ConfettiView()
    }
}
