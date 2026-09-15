# Capabilities Configuration

## Analysis

Based on `us.md` and the Chinese operation guide analysis:

| Keyword Found (guide) | Capability |
|------------------------|------------|
| 拍照 / 相机 / 照片 (camera, photo, scan) | Camera + Photo Library |
| 健康 / HealthKit / Apple 健康 | HealthKit |
| 订阅 / 购买 / StoreKit / 会员 | In-App Purchase (StoreKit 2) |
| iCloud / 同步 / CloudKit | iCloud (CloudKit, optional sync) |
| 通知 / 提醒 (trial pre-expiry, weekly TDEE) | Local Notifications |
| 条码 / Barcode (OFF lookup) | Camera (Vision) |

## Auto-Configured Capabilities

| Capability | Status | Method |
|------------|--------|--------|
| Bundle ID `com.zzoutuo.SureCal` | ✅ Configured | pbxproj edit (was `com.zzoutuo.SureCal.SureCal`, fixed) |
| Deployment Target iOS 17.0 | ✅ Configured | pbxproj edit (test targets normalized from 26.4) |
| Camera usage description | ✅ Configured | `INFOPLIST_KEY_NSCameraUsageDescription` in pbxproj |
| Photo Library usage description | ✅ Configured | `INFOPLIST_KEY_NSPhotoLibraryUsageDescription` in pbxproj |
| HealthKit read/write descriptions | ✅ Configured | `INFOPLIST_KEY_NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` in pbxproj |
| HealthKit entitlement | ✅ Configured | `SureCal.entitlements` + `CODE_SIGN_ENTITLEMENTS` |
| iCloud CloudKit entitlement | ✅ Configured | Container `iCloud.com.zzoutuo.SureCal` declared in entitlements |
| In-App Purchase | ✅ No config needed | StoreKit 2 requires no entitlement; products configured in App Store Connect |
| Local Notifications | ✅ No config needed | No entitlement required |

## Manual Configuration Required

| Capability | Status | Steps |
|------------|--------|-------|
| CloudKit container creation in Apple Developer portal | ⏳ Pending (graceful degradation — app works local-only; iCloud sync is opt-in enhancement) | 1. developer.apple.com → Certificates, IDs & Profiles → Identifiers → `com.zzoutuo.SureCal` → enable iCloud → add container `iCloud.com.zzoutuo.SureCal`. 2. Xcode → Signing & Capabilities → verify CloudKit container appears. |
| StoreKit 2 IAP products in App Store Connect | ⏳ Pending (needed before App Store submission; app runs with StoreKit config file for local testing) | Create `surecal.pro.monthly` ($2.99/mo), `surecal.pro.yearly` ($19.99/yr) + intro offer 7-day free trial in App Store Connect after app record creation. |
| Push notifications certificate | ⏳ Not required | App uses LOCAL notifications only (trial expiry, weekly TDEE) — no APNs needed. |

## No Configuration Needed

- Sign in with Apple — app is no-account by design
- Location Services — not used
- Siri — not used
- Apple Watch — deferred (Watch app listed as Pro feature; base MVP iPhone+iPad only)

## Verification

- Build succeeded after configuration: see PHASE 4+5/6 build reports (code not yet generated at this phase)
- All entitlements correct: ✅ (HealthKit + CloudKit + time-sensitive notifications)
