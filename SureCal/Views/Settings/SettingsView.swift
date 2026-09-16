import SwiftUI
import SwiftData

struct SettingsView: View {
    @StateObject private var purchaseManager = SubscriptionManager.shared
    @StateObject private var quota = QuotaManager.shared
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealLog.date, order: .reverse) private var meals: [MealLog]

    @AppStorage("profile.goal") private var goalRaw = GoalType.lose.rawValue
    @AppStorage("profile.heightCm") private var heightCm = 170.0
    @AppStorage("profile.weightKg") private var weightKg = 70.0
    @AppStorage("profile.age") private var age = 30
    @AppStorage("profile.isMale") private var isMale = true
    @AppStorage("profile.targetKcal") private var targetKcal = 2000
    @AppStorage("icloudSyncEnabled") private var icloudSyncEnabled = false

    @State private var showPaywall = false
    @State private var showContactSupport = false
    @State private var showHealthKitInfo = false
    @State private var showAIConfig = false
    @State private var showCSVPicker = false
    @State private var showExportSheet = false
    @State private var importResult: String?

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                subscriptionSection
                profileSection
                aiSection
                healthSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showContactSupport) { ContactSupportView() }
            .sheet(isPresented: $showHealthKitInfo) { HealthKitInfoView() }
            .sheet(isPresented: $showAIConfig) { AIConfigView() }
            .sheet(isPresented: $showCSVPicker) { CSVPickView { text in
                let summary = CSVImporter.parseAndImport(text: text, context: modelContext)
                importResult = "Imported \(summary.imported) meals, skipped \(summary.skipped) rows."
            } }
            .sheet(isPresented: $showExportSheet) {
                let csv = CSVExporter.export(meals: meals)
                ShareSheet(items: [csv])
            }
        }
    }

    private var subscriptionSection: some View {
        Section {
            if purchaseManager.isPro {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color(red: 0.18, green: 0.36, blue: 1.0))
                    Text("SureCal Pro active")
                        .font(.headline)
                    Spacer()
                }
                Button("Manage Subscription") {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Restore Purchases") {
                    Task { await purchaseManager.restorePurchases() }
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "bolt.shield.fill")
                            .foregroundStyle(Color(red: 0.18, green: 0.36, blue: 1.0))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Pro")
                                .font(.headline)
                            Text("Unlimited scans · \(PricingConfig.yearlyPrice)/year or \(PricingConfig.monthlyPrice)/month · 7-day free trial")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                HStack {
                    Text("Free scans left this month")
                    Spacer()
                    Text("\(quota.remainingFreeScans) of \(QuotaManager.monthlyFreeScans)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        } header: {
            Text("Subscription")
        }
    }

    private var profileSection: some View {
        Section {
            Picker("Goal", selection: $goalRaw) {
                ForEach(GoalType.allCases, id: \.self) { goal in
                    Text(goal.title).tag(goal.rawValue)
                }
            }
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
            Stepper(value: $targetKcal, in: 1000...5000, step: 25) {
                HStack {
                    Text("Daily target")
                    Spacer()
                    Text("\(targetKcal) kcal")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        } header: {
            Text("Your Profile")
        } footer: {
            Text("The dynamic TDEE engine may adjust your weekly target based on your weight trend — you can always override it here.")
        }
    }

    private var aiSection: some View {
        Section {
            Button {
                showAIConfig = true
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color(red: 0.18, green: 0.36, blue: 1.0))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Engine")
                            .font(.headline)
                        Text(KeychainHelper.readString(service: "SureCal", account: "byo_api_key")?.isEmpty == false ? "Custom key configured" : "Built-in engine active")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        } header: {
            Text("AI Engine")
        } footer: {
            Text("Scans use the built-in dual-engine analysis. You can optionally add your own API key — it is stored only on this device.")
        }
    }

    private var healthSection: some View {
        Section {
            HStack {
                Image(systemName: "heart.circle.fill")
                    .foregroundStyle(.red)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("HealthKit Integration")
                        .font(.headline)
                    Text("Sync meals, macros and weight to Apple Health via HealthKit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    showHealthKitInfo = true
                } label: {
                    Text("Learn More")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 2)
            HStack {
                Text("Workout calories")
                Spacer()
                Text("Display only")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            HStack {
                Text("Apple Health (HealthKit)")
                Spacer()
                Image(systemName: "heart.text.square.fill")
                    .foregroundStyle(.red)
            }
        } footer: {
            Text("This app uses the HealthKit framework to write meal energy, macronutrients and body weight to the Apple Health app. This requires your explicit permission. Workout calories are displayed for context only and are never added to your intake budget.")
                .font(.caption2)
        }
    }

    private var dataSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("iCloud Sync (Pro)")
                        .font(.headline)
                    Text("Sync your logs across devices via CloudKit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if purchaseManager.isPro {
                    Toggle("", isOn: $icloudSyncEnabled)
                        .labelsHidden()
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if !purchaseManager.isPro { showPaywall = true }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("iCloud Sync, Pro feature")
            Button {
                if purchaseManager.isPro {
                    showCSVPicker = true
                } else {
                    showPaywall = true
                }
            } label: {
                HStack {
                    Label("Import CSV (MyFitnessPal / Lose It!)", systemImage: "square.and.arrow.down")
                    Spacer()
                    if !purchaseManager.isPro {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Button {
                showExportSheet = true
            } label: {
                Label("Export CSV", systemImage: "square.and.arrow.up")
            }
            if let importResult {
                Text(importResult)
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        } header: {
            Text("Data")
        } footer: {
            Text("Photos stay on this device. iCloud Sync and CSV import are Pro features; exporting your data is always free.")
        }
    }

    private var aboutSection: some View {
        Section {
            Button {
                showContactSupport = true
            } label: {
                Label("Contact Support", systemImage: "envelope")
            }
            Link(destination: PricingConfig.supportURL) {
                Label("Support Page", systemImage: "questionmark.circle")
            }
            Link(destination: PricingConfig.privacyURL) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            Link(destination: PricingConfig.termsURL) {
                Label("Terms of Use", systemImage: "doc.text")
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Data Sources")
                    .font(.subheadline.bold())
                Text("Food nutrition data from Open Food Facts (ODbL) and USDA FoodData Central (public domain).")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("About & Support")
        }
    }
}

enum CSVExporter {
    static func export(meals: [MealLog]) -> String {
        var lines = ["Date,Meal,Food,Kcal,Protein,Carbs,Fat,Source"]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        for meal in meals.sorted(by: { $0.date > $1.date }) {
            for item in meal.items ?? [] {
                let fields = [formatter.string(from: meal.date), meal.mealType, item.name, String(format: "%.0f", item.kcal), String(format: "%.1f", item.protein), String(format: "%.1f", item.carbs), String(format: "%.1f", item.fat), meal.source]
                lines.append(fields.map { $0.contains(",") ? "\"\($0)\"" : $0 }.joined(separator: ","))
            }
        }
        return lines.joined(separator: "\n")
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct CSVPickView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var manualEntry = ""
    let onImport: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Paste the contents of your MyFitnessPal or Lose It! CSV export, then tap Import.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                TextEditor(text: $text)
                    .font(.caption.monospaced())
                    .border(Color(.separator))
                    .padding(.horizontal)
                Button {
                    onImport(text)
                    dismiss()
                } label: {
                    Text("Import")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(text.isEmpty)
                .padding(.horizontal)
                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Import CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
