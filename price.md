# Pricing Configuration

## Monetization Model: Subscription (IAP)

SureCal uses auto-renewable subscriptions (monthly + yearly, no buyout) on top of a permanently free tier. Free tier gets 3 peak-quality dual-engine AI scans per month (rolling reset) plus unlimited manual entry, barcode scanning, and weight tracking — scarcity is quantity, never quality. The 7-day Peak Trial grants full Pro access and auto-reverts to the Free tier (never a silent charge). BYO API Key users get unlimited AI scans at their own API cost ($0 to developer).

## Subscription Group

- **Group Name**: SureCal Pro
- **Reference Name**: SureCal Pro
- **Products in group**: SureCal Pro Monthly, SureCal Pro Yearly (both auto-renewable — no non-consumables exist in this app)

## Subscription Tiers (Auto-Renewable)

### 1. Monthly Subscription

- **Reference Name**: SureCal Pro Monthly
- **Product ID**: `com.zzoutuo.SureCal.pro.monthly`
- **Type**: Auto-renewable subscription
- **Price**: $2.99 USD per month
- **Display Name**: `SureCal Pro Monthly` (19 chars, ≤35 ✅)
- **Description**: `Unlimited dual-engine scans and all Pro features` (48 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: SureCal Pro
- **Restore Purchases**: ✅ Required

### 2. Yearly Subscription (Primary)

- **Reference Name**: SureCal Pro Yearly
- **Product ID**: `com.zzoutuo.SureCal.pro.yearly`
- **Type**: Auto-renewable subscription
- **Price**: $19.99 USD per year (67% savings vs monthly; optional first-year promotional price $9.99 via offer)
- **Display Name**: `SureCal Pro Yearly` (18 chars, ≤35 ✅)
- **Description**: `Unlimited dual-engine scans and all Pro features` (48 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: SureCal Pro (same group as monthly)
- **Restore Purchases**: ✅ Required

## Free Tier (Default)

- **Price**: Free
- **Features**:
  - 3 dual-engine peak-quality AI photo scans per month (rolling monthly reset, next month auto-refresh)
  - Unlimited manual food entry (USDA/OFF lookup)
  - Unlimited barcode scanning (Open Food Facts local DB, offline)
  - Today calorie ring + macro arcs
  - Weight logging + 14-day trend
  - HealthKit integration
- **Conversion hooks**:
  - "3 scans left this month" dots under the shutter button — when depleted: "Upgrade for unlimited scans" (quantity framing only; quality never degrades)
  - Soft paywall after scan quota exhausted — dismissible, no countdown, manual entry stays fully available
  - 7-day Peak Trial framed as "try the full product free" — trial quality equals paid quality

## Pro Features Unlocked (All Paid Tiers)

Cross-referenced with `capabilities.md` — all listed features are implemented in the base app codebase (Watch/Widget deferred; not listed).

| Feature | Free | Pro (All Paid Tiers) |
|---------|:----:|:--------------------:|
| Dual-engine AI photo scans | 3/month | Unlimited |
| Dual-Engine Verified badge + conflict candidates | ✅ (within quota) | ✅ |
| Confidence correction flows (slider / quick quiz) | ✅ | ✅ |
| Asian cuisine specialized recognition prompt | ✅ (within quota) | ✅ |
| Manual food entry | ✅ Unlimited | ✅ |
| Barcode scan (OFF local DB) | ✅ Unlimited | ✅ |
| Weight log + 14-day trend | ✅ | ✅ |
| Dynamic TDEE weekly engine | ✅ | ✅ |
| HealthKit sync | ✅ | ✅ |
| Quick Quiz hidden-calorie capture (oil/sauce) | ✅ | ✅ |
| CSV import (MyFitnessPal / Lose It! export) | ❌ | ✅ |
| iCloud sync (CloudKit, opt-in) | ❌ | ✅ |
| BYO API Key (Cloud Boost — unlimited scans at user's API cost) | ❌ | ✅ |
| Personal calibration knowledge base ("learns your restaurants") | ✅ | ✅ |

## Free Trial

- **Duration**: 7 days
- **Type**: Free trial (introductory offer on subscription; auto-reverts to Free tier at expiry — never silent auto-charge; local notification 24h before expiry)
- **Available for**: Both monthly and yearly tiers (StoreKit 2 introductory offer)
- **Trial compliance**: Trial consumes Pro quota only; user's free 3 monthly scans are untouched and remain after trial ends

## Policy Pages Required

- Support Page: ✅ (must include subscription management + cancellation instructions)
- Privacy Policy: ✅
- Terms of Use (EULA): ✅ (REQUIRED — subscription apps must have Terms)
- **Total policy pages**: 3

## Apple IAP Compliance Checklist

- [x] Auto-renewal terms will be included in Terms of Use
- [x] Cancellation instructions will be included in Support Page ("Manage Subscription" one-tap in Settings)
- [x] Pricing clearly stated in PaywallView (no countdown, no obscured price, prices shown on store page + first onboarding screen)
- [x] Free trial terms included (7-day, auto-revert disclosure, 24h pre-expiry notification)
- [x] Restore purchases functionality implemented (StoreKit 2 `Transaction.currentEntitlements`)
- [x] No external payment links (Guideline 3.1.1)
- [x] No price references to outside-App-Store options
- [x] All IAP descriptions ≤ 55 characters
- [x] All IAP display names ≤ 35 characters
- [x] BYO Key model: Cloud Boost gated by Pro subscription + user's own key — AI scans unlimited for key users, no generation counting against model quality
- [x] No buyout/lifetime product (dual-engine includes consumable cloud inference; lifetime is not offered)
- [x] Free tier manual/barcode/weight features can never be disabled (Guideline 3.1.2(a) durable value)
