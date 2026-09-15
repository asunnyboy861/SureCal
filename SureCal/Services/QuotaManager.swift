import Foundation
import Combine

@MainActor
final class QuotaManager: ObservableObject {
    static let shared = QuotaManager()

    static let monthlyFreeScans = 3

    @Published var scansUsedThisMonth: Int
    @Published var currentMonth: String

    private let defaults = UserDefaults.standard

    var remainingFreeScans: Int { max(0, Self.monthlyFreeScans - scansUsedThisMonth) }
    var canVerify: Bool { SubscriptionManager.shared.isPro || remainingFreeScans > 0 }
    var canScan: Bool { SubscriptionManager.shared.isPro || remainingFreeScans > 0 }

    private init() {
        let month = Self.currentMonthKey()
        let storedMonth = defaults.string(forKey: "quota.currentMonth") ?? month
        let used = storedMonth == month ? defaults.integer(forKey: "quota.scansUsed") : 0
        if storedMonth != month {
            defaults.set(0, forKey: "quota.scansUsed")
            defaults.set(month, forKey: "quota.currentMonth")
        }
        scansUsedThisMonth = used
        currentMonth = month
    }

    func consumeScan() {
        guard !SubscriptionManager.shared.isPro else { return }
        scansUsedThisMonth += 1
        defaults.set(scansUsedThisMonth, forKey: "quota.scansUsed")
    }

    func consumeVerify() {
        guard !SubscriptionManager.shared.isPro else { return }
        scansUsedThisMonth += 1
        defaults.set(scansUsedThisMonth, forKey: "quota.scansUsed")
    }

    nonisolated static func currentMonthKey(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
}
