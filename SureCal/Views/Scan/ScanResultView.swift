import SwiftUI
import SwiftData

struct ScanResultView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let image: UIImage

    @StateObject private var orchestrator = DualEngineOrchestrator.shared
    @StateObject private var quota = QuotaManager.shared
    @State private var scanAnalysis: FoodAnalysis?
    @State private var outcome: DualEngineOrchestrator.ScanOutcome?
    @State private var errorText: String?
    @State private var step: ScanResultStep = .highConfidence
    @State private var startedAt = Date()
    @State private var saved = false
    @State private var showQuiz = false
    @State private var mealType = Self.defaultMealType()

    nonisolated static func defaultMealType(date: Date = Date()) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11: return "breakfast"
        case 11..<15: return "lunch"
        case 15..<17: return "snack"
        case 17..<22: return "dinner"
        default: return "snack"
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let errorText {
                    errorView(errorText)
                } else if let analysis = scanAnalysis {
                    resultView(analysis)
                } else {
                    loadingView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Scan Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task { await runScan() }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            if orchestrator.phase == .verifying {
                ProgressView("Second engine is cross-checking…")
            } else {
                ProgressView("Analyzing your meal…")
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(message)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Try Again") {
                errorText = nil
                Task { await runScan() }
            }
            .buttonStyle(.borderedProminent)
            Button("Log Manually Instead") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
    }

    private func resultView(_ analysis: FoodAnalysis) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                statusHeader(analysis)
                confidenceStrip(analysis)
                ForEach(Array(analysis.items.enumerated()), id: \.offset) { index, _ in
                    FoodResultRow(item: Binding(
                        get: { scanAnalysis?.items[index] ?? FoodAnalysisItem(name: "", portionGrams: 0, kcal: 0, protein: 0, carbs: 0, fat: 0, confidence: 0) },
                        set: { scanAnalysis?.items[index] = $0 }
                    ))
                }
                Picker("Meal", selection: $mealType) {
                    Text("Breakfast").tag("breakfast")
                    Text("Lunch").tag("lunch")
                    Text("Dinner").tag("dinner")
                    Text("Snack").tag("snack")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                actionButtons(analysis)
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showQuiz) {
            QuickQuizView(analysis: analysis) { quizGrams, oilGrams in
                applyQuizResult(analysis: analysis, quizGrams: quizGrams, oilGrams: oilGrams)
                save()
            }
        }
    }

    private func statusHeader(_ analysis: FoodAnalysis) -> some View {
        VStack(spacing: 8) {
            if outcome?.verified == true {
                DualEngineBadge()
            } else if outcome?.conflicted == true {
                Label("The two AIs see this differently — pick what looks right", systemImage: "arrow.triangle.branch")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }
            if step == .mediumConfidence {
                Text("The AI is about \(Int(analysis.overallConfidence * 100))% sure — adjust the slider if the portion looks off")
                    .font(.caption)
                    .foregroundStyle(.purple)
                    .multilineTextAlignment(.center)
            }
            if step == .quickQuiz {
                Text("This one's tricky — can you help me out for 5 seconds?")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }

    private func confidenceStrip(_ analysis: FoodAnalysis) -> some View {
        HStack {
            Text("Total")
                .font(.headline)
            Spacer()
            let totals = totals(analysis)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(totals.kcal)) kcal")
                    .font(.title2.bold().monospacedDigit())
                Text("P \(Int(totals.protein))g · C \(Int(totals.carbs))g · F \(Int(totals.fat))g")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private func actionButtons(_ analysis: FoodAnalysis) -> some View {
        VStack(spacing: 10) {
            Button {
                if step == .quickQuiz {
                    showQuiz = true
                } else {
                    save()
                }
            } label: {
                Text(step == .quickQuiz ? "Quick Quiz (5 sec)" : "Looks right ✓")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            if step != .quickQuiz {
                Button {
                    showQuiz = true
                } label: {
                    Text("Let me fix it")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(.horizontal)
        .disabled(saved)
    }

    private func totals(_ analysis: FoodAnalysis) -> (kcal: Double, protein: Double, carbs: Double, fat: Double) {
        let kcal = analysis.items.reduce(0) { $0 + $1.kcal }
        let protein = analysis.items.reduce(0) { $0 + $1.protein }
        let carbs = analysis.items.reduce(0) { $0 + $1.carbs }
        let fat = analysis.items.reduce(0) { $0 + $1.fat }
        return (kcal, protein, carbs, fat)
    }

    private func runScan() async {
        startedAt = Date()
        guard let imageData = preprocessImage(image) else {
            errorText = "Could not process the photo."
            return
        }
        let defaults = UserDefaults.standard
        let goal = GoalType(rawValue: defaults.string(forKey: "profile.goal") ?? "lose") ?? .lose
        let context = MealContext(mealType: mealType, goal: goal, userNote: nil)
        do {
            let result = try await DualEngineOrchestrator.shared.scan(imageData: imageData, context: context)
            outcome = result
            scanAnalysis = result.analysis
            step = Self.routingStep(for: result.analysis, in: modelContext)
        } catch {
            errorText = error.localizedDescription
        }
    }

    nonisolated static func routingStep(for analysis: FoodAnalysis, in context: ModelContext) -> ScanResultStep {
        let fingerprint = ConfidenceRouter.fingerprint(for: analysis)
        var calibration: CalibrationRecord?
        if let results = try? context.fetch(FetchDescriptor<CalibrationRecord>()),
           let match = results.first(where: { $0.fingerprint == fingerprint }) {
            calibration = match
        }
        return ConfidenceRouter.route(analysis, calibration: calibration)
    }

    private func applySliderChange(itemIndex: Int, scale: Double) {
        guard var updated = scanAnalysis else { return }
        var item = updated.items[itemIndex]
        let newGrams = item.portionGrams * scale
        let factor = newGrams / max(item.portionGrams, 1)
        item.kcal *= factor
        item.protein *= factor
        item.carbs *= factor
        item.fat *= factor
        item.portionGrams = newGrams
        updated.items[itemIndex] = item
        scanAnalysis = updated
    }

    private func applyQuizResult(analysis: FoodAnalysis, quizGrams: Double?, oilGrams: Double) {
        guard !saved else { return }
        if let grams = quizGrams, var first = analysis.items.first {
            let factor = grams / max(first.portionGrams, 1)
            first.kcal *= factor
            first.protein *= factor
            first.carbs *= factor
            first.fat *= factor
            first.portionGrams = grams
            scanAnalysis?.items[0] = first
        }
        if oilGrams > 0, let idx = scanAnalysis?.items.indices.last {
            scanAnalysis?.items[idx].kcal += oilGrams * 9
            scanAnalysis?.items[idx].hiddenOilGrams = oilGrams
        }
    }

    private func save() {
        guard !saved, let analysis = scanAnalysis else { return }
        saved = true
        let meal = MealLog(date: Date(), mealType: mealType, source: outcome?.engineSource ?? "ai_glm")
        meal.verifiedBadge = outcome?.verified == true
        meal.wasCorrected = Date().timeIntervalSince(startedAt) > 1.2
        meal.correctionSeconds = Date().timeIntervalSince(startedAt)
        if let data = image.jpegData(compressionQuality: 0.3) {
            meal.photoData = data
        }
        meal.items = analysis.items.map { item in
            FoodEntry(name: item.name, grams: item.portionGrams, kcal: item.kcal, protein: item.protein, carbs: item.carbs, fat: item.fat, confidence: item.confidence)
        }
        for entry in meal.items ?? [] { entry.meal = meal }
        modelContext.insert(meal)

        QuotaManager.shared.consumeScan()
        recordCalibration(analysis: analysis, corrected: meal.wasCorrected)
        try? modelContext.save()
        Task {
            await HealthKitWriter.shared.write(meal: meal)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }

    private func recordCalibration(analysis: FoodAnalysis, corrected: Bool) {
        let fingerprint = ConfidenceRouter.fingerprint(for: analysis)
        let results = (try? modelContext.fetch(FetchDescriptor<CalibrationRecord>())) ?? []
        let record = results.first(where: { $0.fingerprint == fingerprint }) ?? {
            let new = CalibrationRecord(fingerprint: fingerprint)
            modelContext.insert(new)
            return new
        }()
        if corrected {
            record.correctionHistory.append(min(0.5, max(0, 1.0 - analysis.overallConfidence)))
            record.correctionHistory = Array(record.correctionHistory.suffix(20))
            record.averageUserDownwardCorrection = record.correctionHistory.reduce(0, +) / Double(max(record.correctionHistory.count, 1))
        }
        record.hitCount += 1
    }
}

struct FoodResultRow: View {
    @Binding var item: FoodAnalysisItem
    @State private var scale: Double = 1.0
    @State private var appliedScale: Double = 1.0

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(item.name)
                    .font(.headline)
                Spacer()
                ConfidenceBadge(confidence: item.confidence)
            }
            HStack {
                Text("\(Int(item.portionGrams)) g")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(item.kcal)) kcal")
                        .font(.title3.bold().monospacedDigit())
                    Text("P \(Int(item.protein))g · C \(Int(item.carbs))g · F \(Int(item.fat))g")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Slider(value: $scale, in: 0.5...2.0, step: 0.05)
                .onChange(of: scale) { _, newValue in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    applyScale(newValue / appliedScale)
                    appliedScale = newValue
                }
                .accessibilityLabel("Adjust portion size")
            if let alternatives = item.alternatives, !alternatives.isEmpty {
                HStack {
                    Text("Not it?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(alternatives.prefix(3), id: \.self) { alt in
                        Button {
                            item.name = alt
                        } label: {
                            Text(alt)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.tertiarySystemFill), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    private func applyScale(_ factor: Double) {
        item.portionGrams *= factor
        item.kcal *= factor
        item.protein *= factor
        item.carbs *= factor
        item.fat *= factor
    }
}
