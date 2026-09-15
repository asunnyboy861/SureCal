import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var purchaseManager = SubscriptionManager.shared
    @State private var purchasing = false
    @State private var successMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color(red: 0.18, green: 0.36, blue: 1.0))
                        .padding(.top, 16)
                    Text("SureCal Pro")
                        .font(.largeTitle.bold())
                    Text("Unlimited dual-engine scans — the same peak quality every time.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 10) {
                        featureRow("infinity", "Unlimited dual-engine photo scans")
                        featureRow("slider.horizontal.3", "3-second portion correction engine")
                        featureRow("questionmark.bubble", "Quick Quiz hidden-calorie capture")
                        featureRow("globe.asia.australia", "Asian cuisine specialized recognition")
                        featureRow("chart.line.uptrend.xyaxis", "Dynamic TDEE weekly engine")
                        featureRow("icloud", "iCloud sync & CSV import")
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    if purchaseManager.products.isEmpty {
                        VStack(spacing: 8) {
                            Text("Monthly — \(PricingConfig.monthlyPrice)/month")
                            Text("Yearly — \(PricingConfig.yearlyPrice)/year")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        ProgressView()
                    } else {
                        ForEach(purchaseManager.products, id: \.id) { product in
                            productButton(product)
                        }
                        .padding(.horizontal)
                    }

                    Button {
                        Task {
                            await purchaseManager.restorePurchases()
                            if purchaseManager.isPro { dismiss() }
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(.subheadline)
                    }
                    .padding(.top, 4)

                    VStack(spacing: 10) {
                        HStack(spacing: 24) {
                            Link("Privacy Policy", destination: PricingConfig.privacyURL)
                            Link("Terms of Use", destination: PricingConfig.termsURL)
                        }
                        .font(.caption2)
                        Text(PricingConfig.autoRenewalDisclosure)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close")
                }
            }
            .alert("Notice", isPresented: .init(get: { purchaseManager.loadError != nil }, set: { _ in })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(purchaseManager.loadError ?? "")
            }
        }
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color(red: 0.18, green: 0.36, blue: 1.0))
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }

    private func productButton(_ product: Product) -> some View {
        Button {
            purchasing = true
            Task {
                let success = await purchaseManager.purchase(product)
                purchasing = false
                if success {
                    NotificationHelper.scheduleTrialExpiryReminder()
                    dismiss()
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName.isEmpty ? planName(product) : product.displayName)
                        .font(.headline)
                    Text(planCaption(product))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.headline.monospacedDigit())
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(purchasing)
    }

    private func planName(_ product: Product) -> String {
        product.id == PricingConfig.yearlyID ? "Yearly" : "Monthly"
    }

    private func planCaption(_ product: Product) -> String {
        if let intro = product.subscription?.introductoryOffer, intro.paymentMode == .freeTrial {
            return "7-day free trial included"
        }
        return product.id == PricingConfig.yearlyID ? "Best value" : "Flexible"
    }
}
