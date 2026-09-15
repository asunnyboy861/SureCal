import Foundation

enum GLMConfig {
    static let endpoint = URL(string: "https://open.bigmodel.cn/api/paas/v4/chat/completions")!
    static let model = "glm-5.3-flash"
    static let apiKey = "REDACTED"
    static let timeout: TimeInterval = 90
}

enum PricingConfig {
    static let monthlyID = "com.zzoutuo.SureCal.pro.monthly"
    static let yearlyID = "com.zzoutuo.SureCal.pro.yearly"
    static let trialDays = 7
    static let monthlyPrice = "$2.99"
    static let yearlyPrice = "$19.99"
    static let privacyURL = URL(string: "https://asunnyboy861.github.io/SureCal/privacy.html")!
    static let termsURL = URL(string: "https://asunnyboy861.github.io/SureCal/terms.html")!
    static let supportURL = URL(string: "https://asunnyboy861.github.io/SureCal/support.html")!
    static let autoRenewalDisclosure = "Subscription automatically renews unless canceled at least 24 hours before the end of the current period. You can manage or cancel anytime in Settings."
}
