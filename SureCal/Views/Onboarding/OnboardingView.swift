import SwiftUI

struct OnboardingView: View {
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @AppStorage("profile.goal") private var goalRaw = GoalType.lose.rawValue
    @AppStorage("profile.heightCm") private var heightCm = 170.0
    @AppStorage("profile.weightKg") private var weightKg = 70.0
    @AppStorage("profile.age") private var age = 30
    @AppStorage("profile.isMale") private var isMale = true
    @AppStorage("profile.targetKcal") private var targetKcal = 2000

    @State private var screen = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Capsule()
                        .fill(index <= screen ? Color(red: 0.18, green: 0.36, blue: 1.0) : Color(.systemGray4))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            switch screen {
            case 0: welcomeScreen
            case 1: goalScreen
            default: bodyScreen
            }
        }
        .background(Color(.systemBackground))
    }

    private var welcomeScreen: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 72))
                .foregroundStyle(Color(red: 0.18, green: 0.36, blue: 1.0))
            Text("Photo calories you can trust.")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("Snap a meal, get an estimate with an honest confidence score — and fix it in seconds if it's off.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            VStack(spacing: 8) {
                Label("3 free scans every month", systemImage: "sparkles")
                Label("7-day full trial, cancel anytime", systemImage: "clock")
                Label("No account needed", systemImage: "lock.shield")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            Spacer()
            Button {
                withAnimation { screen = 1 }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private var goalScreen: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("What's your goal?")
                .font(.title.bold())
            VStack(spacing: 14) {
                ForEach(GoalType.allCases, id: \.self) { goal in
                    Button {
                        goalRaw = goal.rawValue
                        withAnimation { screen = 2 }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(goal.title).font(.headline).foregroundStyle(.primary)
                                Text(goal.subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                        }
                        .padding(20)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Goal: \(goal.title)")
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private var bodyScreen: some View {
        VStack(spacing: 24) {
            Text("About you")
                .font(.title.bold())
                .padding(.top, 32)
            Form {
                Picker("Height", selection: $heightCm) {
                    ForEach(Array(stride(from: 130.0, through: 215.0, by: 1.0)), id: \.self) { value in
                        Text("\(Int(value)) cm").tag(value)
                    }
                }
                Picker("Weight", selection: $weightKg) {
                    ForEach(Array(stride(from: 35.0, through: 180.0, by: 0.5)), id: \.self) { value in
                        Text(String(format: "%.1f kg", value)).tag(value)
                    }
                }
                Picker("Age", selection: $age) {
                    ForEach(14...90, id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                Picker("Sex", selection: $isMale) {
                    Text("Male").tag(true)
                    Text("Female").tag(false)
                }
            }
            VStack(spacing: 8) {
                Text("Your estimated daily target")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(computedTarget) kcal")
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .monospacedDigit()
            }
            Button {
                targetKcal = computedTarget
                onboardingComplete = true
            } label: {
                Text("Start Tracking")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private var computedTarget: Int {
        TDEECalculator.target(goal: GoalType(rawValue: goalRaw) ?? .lose, heightCm: heightCm, weightKg: weightKg, age: age, isMale: isMale)
    }
}

extension GoalType {
    var title: String {
        switch self {
        case .lose: return "Lose weight"
        case .maintain: return "Maintain"
        case .gain: return "Build muscle"
        }
    }

    var subtitle: String {
        switch self {
        case .lose: return "Gentle deficit based on your numbers"
        case .maintain: return "Stay at your current weight"
        case .gain: return "Support training with a surplus"
        }
    }
}
