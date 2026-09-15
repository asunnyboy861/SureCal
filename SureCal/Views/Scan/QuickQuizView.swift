import SwiftUI

struct QuickQuizView: View {
    @Environment(\.dismiss) private var dismiss
    let analysis: FoodAnalysis
    let onComplete: (_ portionGrams: Double?, _ oilGrams: Double) -> Void

    @State private var questionIndex = 0
    @State private var oilScale: Double = 1
    @State private var portionGrams: Double?

    private var questions: [QuickQuizQuestion] {
        var questions: [QuickQuizQuestion] = []
        if analysis.isMixedDish {
            questions.append(QuickQuizQuestion(id: .oil, title: "How much oil was used in cooking?", systemImage: "drop.fill"))
        }
        if analysis.overallConfidence < 0.5, let first = analysis.items.first {
            questions.append(QuickQuizQuestion(id: .portion, title: "How much \(first.name) was there?", systemImage: "scalemass.fill"))
        }
        if questions.isEmpty {
            questions.append(QuickQuizQuestion(id: .oil, title: "Was any oil or sauce added?", systemImage: "drop.fill"))
        }
        return questions
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                HStack(spacing: 6) {
                    ForEach(0..<questions.count, id: \.self) { index in
                        Capsule()
                            .fill(index <= questionIndex ? Color.orange : Color(.systemGray4))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 24)

                let question = questions[questionIndex]
                VStack(spacing: 20) {
                    Image(systemName: question.systemImage)
                        .font(.system(size: 44))
                        .foregroundStyle(.orange)
                    Text(question.title)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    questionControl(question)
                }
                Spacer()
                Button {
                    nextQuestion()
                } label: {
                    Text(questionIndex < questions.count - 1 ? "Next" : "Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.orange)
            }
            .padding()
            .navigationTitle("Quick Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Skip") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func questionControl(_ question: QuickQuizQuestion) -> some View {
        switch question.id {
        case .oil:
            VStack(spacing: 12) {
                Slider(value: $oilScale, in: 0...4, step: 1)
                Text(oilLabel)
                    .font(.headline)
                Text("\(Int(oilScale * 5)) g oil ≈ \(Int(oilScale * 5 * 9)) kcal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
        case .portion:
            if let base = analysis.items.first {
                VStack(spacing: 12) {
                    Slider(value: Binding(get: { portionGrams ?? base.portionGrams }, set: { portionGrams = $0 }), in: base.portionGrams * 0.5...base.portionGrams * 2, step: 10)
                    Text("\(Int(portionGrams ?? base.portionGrams)) g")
                        .font(.headline.monospacedDigit())
                }
                .padding(.horizontal, 8)
            }
        }
    }

    private var oilLabel: String {
        switch oilScale {
        case 0: return "None"
        case 1: return "Light"
        case 2: return "Medium"
        case 3: return "Lots"
        default: return "Very heavy"
        }
    }

    private func nextQuestion() {
        if questionIndex < questions.count - 1 {
            questionIndex += 1
        } else {
            let grams = questions.contains(where: { $0.id == .portion }) ? portionGrams : nil
            let oil = questions.contains(where: { $0.id == .oil }) ? oilScale * 5 : 0
            onComplete(grams, oil)
            dismiss()
        }
    }
}

struct QuickQuizQuestion: Identifiable {
    enum QuestionKind {
        case oil
        case portion
    }

    let id: QuestionKind
    let title: String
    let systemImage: String
}
