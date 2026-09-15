import SwiftUI
import SwiftData

struct CalorieRing: View {
    let consumed: Double
    let target: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let proteinTarget: Double
    let carbsTarget: Double
    let fatTarget: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 14)
            Circle()
                .trim(from: 0, to: min(1, consumed / max(target, 1)))
                .stroke(ringColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: consumed)
            VStack(spacing: 2) {
                Text("\(Int(consumed))")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("of \(Int(target)) kcal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if consumed > target {
                    Text("over budget")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .frame(width: 200, height: 200)
        .overlay(macroArcs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Consumed \(Int(consumed)) of \(Int(target)) kilocalories")
    }

    private var ringColor: Color {
        consumed > target ? Color(.systemOrange) : Color(red: 0.18, green: 0.36, blue: 1.0)
    }

    private var macroArcs: some View {
        MacroArcs(protein: protein, carbs: carbs, fat: fat, proteinTarget: proteinTarget, carbsTarget: carbsTarget, fatTarget: fatTarget)
            .frame(width: 240, height: 240)
    }
}

struct MacroArcs: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    let proteinTarget: Double
    let carbsTarget: Double
    let fatTarget: Double

    var body: some View {
        ZStack {
            ArcShape(progress: protein / max(proteinTarget, 1))
                .stroke(Color.mint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
            ArcShape(progress: carbs / max(carbsTarget, 1))
                .stroke(Color.yellow, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .padding(6)
            ArcShape(progress: fat / max(fatTarget, 1))
                .stroke(Color.pink, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .padding(12)
        }
    }
}

struct ArcShape: Shape {
    let progress: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: min(rect.width, rect.height) / 2 - 4,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(-90 + 360 * min(1, max(0, progress))),
                    clockwise: false)
        return path
    }
}

struct ShutterButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.18, green: 0.36, blue: 1.0))
                    .frame(width: 96, height: 96)
                    .shadow(color: .blue.opacity(0.35), radius: 12, y: 4)
                Circle()
                    .stroke(Color.white.opacity(0.6), lineWidth: 3)
                    .frame(width: 78, height: 78)
                Image(systemName: "camera.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .accessibilityLabel("Scan a meal")
        .accessibilityHint("Opens the camera to analyze your meal photo")
    }
}

struct ConfidenceBadge: View {
    let confidence: Double

    var body: some View {
        let band = ConfidenceRouter.band(confidence)
        HStack(spacing: 4) {
            Image(systemName: iconName)
            Text(label)
        }
        .font(.caption2.bold())
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(bandColor.opacity(0.15), in: Capsule())
        .foregroundStyle(bandColor)
        .accessibilityLabel("Confidence \(Int(confidence * 100)) percent")
    }

    private var bandColor: Color {
        switch ConfidenceRouter.band(confidence) {
        case .high: return .green
        case .medium: return .purple
        case .low: return .orange
        }
    }

    private var iconName: String {
        switch ConfidenceRouter.band(confidence) {
        case .high: return "checkmark.circle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .low: return "questionmark.circle.fill"
        }
    }

    private var label: String {
        "AI is \(Int(confidence * 100))% sure"
    }
}

struct DualEngineBadge: View {
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark.seal.fill")
            Text("Dual-Engine Verified")
        }
        .font(.caption.bold())
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .foregroundStyle(Color(red: 0.18, green: 0.36, blue: 1.0))
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityLabel("Verified by two independent AI engines")
    }
}
