import SwiftUI

struct HealthKitInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.red)
                        .padding(.top, 24)
                    Text("HealthKit Integration")
                        .font(.title.bold())
                    Text("SureCal integrates with Apple Health through the HealthKit framework to keep your nutrition data in one place.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 14) {
                        infoRow("fork.knife", "What we write", "Meal calories, protein, carbs, fat and your logged body weight are saved to Apple Health when you confirm a meal or log a weight entry.")
                        infoRow("figure.run", "What we read", "Your daily active (workout) energy — displayed for context only. Workout calories are never added to your intake budget.")
                        infoRow("lock.shield", "Your control", "HealthKit access is requested only after your second app launch, with an explanation. You can revoke permission anytime in the Apple Health app.")
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    Text("General wellness information — not medical advice.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.bottom, 24)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func infoRow(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.red)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct AIConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var endpoint = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
    @State private var model = "glm-5.3-flash"
    @State private var saved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("SureCal works out of the box with its built-in analysis engine. Optionally, add your own API key from any OpenAI-compatible provider (GLM, DeepSeek, OpenAI, and more) for unlimited scans at your own cost.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section {
                    SecureField("API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                    TextField("Endpoint URL", text: $endpoint)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Model ID", text: $model)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Custom API (optional)")
                } footer: {
                    Text("Your key is stored in the iOS Keychain on this device only — it is never sent anywhere except your chosen endpoint.")
                }
                Section {
                    Button("Save Key", role: .none) {
                        KeychainHelper.saveString(apiKey, service: "SureCal", account: "byo_api_key")
                        KeychainHelper.saveString(endpoint, service: "SureCal", account: "byo_endpoint")
                        KeychainHelper.saveString(model, service: "SureCal", account: "byo_model")
                        saved = true
                    }
                    .disabled(apiKey.isEmpty)
                    if saved {
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    Button("Remove Key", role: .destructive) {
                        KeychainHelper.delete(service: "SureCal", account: "byo_api_key")
                        KeychainHelper.delete(service: "SureCal", account: "byo_endpoint")
                        KeychainHelper.delete(service: "SureCal", account: "byo_model")
                        apiKey = ""
                        saved = true
                    }
                }
            }
            .navigationTitle("AI Engine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                apiKey = KeychainHelper.readString(service: "SureCal", account: "byo_api_key") ?? ""
                endpoint = KeychainHelper.readString(service: "SureCal", account: "byo_endpoint") ?? endpoint
                model = KeychainHelper.readString(service: "SureCal", account: "byo_model") ?? model
            }
        }
    }
}
