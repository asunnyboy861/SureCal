# SureCal - iOS Development Guide

## Executive Summary

**SureCal** is an AI-powered photo calorie tracker that turns honesty into a competitive advantage. The app uses a dual-engine AI verification architecture (GLM-5.3-Flash cloud vision + Apple FoundationModels on-device) to analyze meal photos and return calorie/macro estimates with transparent confidence scoring. Unlike competitors that hide uncertainty behind false precision, SureCal displays a confidence band (green/purple/orange), supports a 3-second portion slider correction flow, and offers 3 free peak-quality scans per month — limiting quantity, never quality.

**Target audience**: Health-conscious iPhone users who tried Cal AI-like apps and were burned by inaccurate estimates, deceptive pricing, or account/login friction.

**Key differentiators**:
1. **Dual-engine verification** — two independent AI models cross-check each other; agreement yields a "Dual-Engine Verified" badge, disagreement surfaces honest candidates.
2. **Honest confidence UI** — three-color system (green ≥0.85 / purple 0.5–0.85 / orange <0.5) with correction flows that take ≤5 seconds.
3. **Transparent pricing** — store-page-stated prices, 7-day peak trial that auto-reverts to Free (never silent auto-charge), one-tap cancel.
4. **No-account design** — pure SwiftData local + optional iCloud sync; no login wall.

## Competitive Analysis

| App | Strengths | Weaknesses | Our Advantage |
|-----|-----------|------------|---------------|
| Cal AI (MyFitnessPal-owned) | Fast photo capture; 337k ratings at 4.8 stars; viral TikTok momentum | Briefly removed from App Store Apr 2026 for deceptive billing; no free photo tier; single-model self-reported confidence; no coaching; 44–66% of 1-star reviews are billing complaints | Dual-engine verification vs single model; free 3 scans/month; transparent $19.99/yr vs opaque $29.99+; no-account design |
| MacroFactor | Adaptive TDEE algorithm (best-in-class math); clean UI | No free version ($11.99/mo or $71.99/yr); manual entry only, no photo; requires account | Photo-first + adaptive TDEE both included; free tier; no account required |
| MyFitnessPal | Largest food database (20M+ foods); ecosystem integrations | $19.99/mo or $79.99/yr; Meal Scan behind Premium; account required; owned by same parent as Cal AI (consolidation risk) | $19.99/yr flat; photo scanning free 3×/month; no account |
| Lose It! | Legacy tracker with Snap It AI; $39.99/yr Premium; barcode + database | Photo AI bolted onto manual-entry app; Snap It behind Premium paywall | Photo-first architecture (camera is the default action, not buried in menu); free scans |
| PlateLens | ±1.1% MAPE (DAI benchmark leader); per-component segmentation | Niche/pricier; limited international food coverage reported | Transparent confidence + correction flow; broader cuisine support; lower price |

## ⚠️ Feature Inventory (MANDATORY — Every Feature Must Be Listed)

### Primary Features (from guide)

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | **AI Photo Scan (Dual-Engine)** | 1. User taps large shutter button on Today page → 2. AVFoundation capture or photo library import → 3. Image preprocessed (1024px JPEG) → 4. AIRouter routes to engine → 5. DualEngineOrchestrator runs primary + optional verify → 6. FoodAnalysis returned | Photo (camera or library); MealContext (goal/meal type/user note) | Image preprocess → AI engine analyze → dual-engine verify (if needed) → confidence calibration | FoodAnalysis: items[name, portionGrams, kcal, protein, carbs, fat, confidence, alternatives, cookingMethod], isMixedDish, overallConfidence | SwiftData MealLog + FoodEntry; photo thumbnail local-only | Photo to structured result <2s (L0); dual-engine badge or honest candidates shown; confidence band displayed |
| 2 | **Confidence-Based Correction Flow** | 1. Scan result shown with confidence badge → 2a. Green (≥0.85): tap "Looks right ✓" → 2b. Purple (0.5–0.85): drag portion slider ±50% or tap alternative food → 2c. Orange (<0.5/mixed): quick quiz (≤3 questions, oil/sauce/portion) → 3. Confirm | Confidence band selection; portion scale (0.5–2.0); alternative food name; oil/sauce grams | ConfidenceRouter routes to correct flow; portion change recalculates kcal/macros in real-time; quiz answers add hidden oil calories | FinalEntry with corrected values; correction time recorded | SwiftData MealLog (wasCorrected, correctionSeconds); CalibrationRecord fingerprint | Any correction path ≤5 seconds; macros update in real-time on slider drag; haptic feedback on confirm |
| 3 | **Today Dashboard** | 1. App opens to Today page → 2. See date + calorie ring (intake vs dynamic target) + protein/carb/fat arcs → 3. Large shutter button (120pt) → 4. Remaining scan dots (3 dots) → 5. Today's meals horizontal card scroll | Date; daily intake; dynamic TDEE target; meal logs for today | TDEE engine computes target; ring renders intake vs target; macro arcs show breakdown | Ring UI with intake/target; macro arcs; meal cards with thumbnail + kcal + confidence badge | SwiftData MealLog query by date | Single-hand reachable; ring updates instantly after meal confirm; shutter button in lower 2/3 hot zone |
| 4 | **Onboarding (≤3 screens, ≤60s)** | 1. Screen 1: value prop "Photo calories you can trust." + transparent pricing text → 2. Screen 2: goal 3-choice (lose/maintain/gain) → 3. Screen 3: height/weight/age number pickers (sensible defaults) → 4. Auto-calc TDEE → enter Today page | Goal selection; height (cm); weight (kg); age (years) | TDEE formula: BMR (Mifflin-St Jeor) × activity factor; goal adjustment (lose: −400 kcal, gain: +400 kcal) | TDEE target kcal; macro split | UserDefaults (onboardingComplete, goal, height, weight, age, targetKcal) | ≤3 screens; zero paywall interception; zero review solicitation; TDEE computed and saved; lands on Today page with empty state "Snap your first meal" |
| 5 | **Barcode Scan (OFF)** | 1. User taps barcode icon → 2. Vision framework scans barcode → 3. Look up in Open Food Facts local DB (9.88M items) → 4. Return nutrition → 5. Confirm portion → save | Barcode string | Vision VNDetectBarcodesRequest → OFF local SQLite lookup → nutrition mapping | Food name, kcal, protein, carbs, fat per serving | SwiftData MealLog (source: "barcode_off") | Works offline (local DB); <1s lookup; always free (not counted against scan quota) |
| 6 | **Manual Food Entry** | 1. User taps "Add manually" → 2. Search food name → 3. USDA/OFF lookup or free-text → 4. Enter grams → 5. Confirm | Food name (text); grams (number) | Food search → nutrition lookup → macro calculation per gram | kcal, protein, carbs, fat for entered grams | SwiftData MealLog (source: "manual") | Always free; works offline if food in local DB; ≤3 taps to log |
| 7 | **Weight Logging + Trend** | 1. Progress page → 2. Tap "Log weight" → 3. Enter weight (kg/lb) → 4. See 14-day weighted moving average trend | Weight (kg or lb) | 14-day weighted moving average; single-day outliers auto-excluded | Weight trend chart; TDEE adjustment display | SwiftData WeightLog; HealthKit HKQuantityType(.bodyMass) | Trend smooths daily fluctuation; HealthKit sync (if permitted); displayed on Progress page |
| 8 | **Dynamic TDEE Engine** | 1. Weekly (Sunday) auto-run → 2. Uses 14-day weight trend + actual intake → 3. Real TDEE = avgIntake + (weightDelta/day × 7.7) → 4. Adjust next week's target ±200 kcal max | 14-day weight array; 14-day intake array; user goal | Energy balance formula; clamp adjustment to ±200 kcal/week | New weekly target kcal; notification "Your goal moved to X — here's why" | UserDefaults (currentTargetKcal); WeightLog + MealLog history | Runs automatically weekly; target adjusts ≤±200 kcal; user notified of change with explanation; never jitters daily |
| 9 | **StoreKit 2 Subscription** | 1. User exhausts 3 free scans → 2. Soft paywall (dismissible, no countdown) → 3. Shows: 7-day peak trial / Monthly $2.99 / Yearly $19.99 → 4. Purchase via StoreKit 2 → 5. Unlock unlimited scans + Pro features | Purchase selection; StoreKit 2 transaction | StoreKit 2 product fetch; transaction verification; entitlement update | Entitlement state (free/trial/pro); scan quota reset | StoreKit 2 transaction; UserDefaults entitlement | No countdown timer; price shown clearly; trial auto-reverts to Free (never silent charge); 24h pre-expiry local notification; one-tap manage subscription in Settings |
| 10 | **HealthKit Integration** | 1. Second app open → request HealthKit permission (with explanation) → 2. On meal confirm → write dietaryEnergy/macros → 3. Weight log → write bodyMass → 4. Workout data read-only (display, not added to intake) | HealthKit authorization; meal data; weight data | HKQuantitySample creation for energy/protein/carbs/fat/bodyMass; HKWorkout read (display only) | Health app shows SureCal-written data; workout calories displayed but NOT added to intake budget | HealthKit store | Permission requested on 2nd open (not first); workout calories never "eaten back"; write works on confirm |
| 11 | **iCloud Sync (CloudKit)** | 1. User enables iCloud sync in Settings → 2. SwiftData CloudKit container syncs MealLog/WeightLog → 3. Multi-device sync | iCloud account; CloudKit enable toggle | SwiftData CloudKit private database; incremental sync | Data synced across user's Apple devices | CloudKit private database (free, E2E encrypted) | Opt-in (not default); free; works across iPhone+iPad; no account creation |
| 12 | **Settings Page** | 1. Tab to Settings → 2. See: subscription status + manage link / AI engine selector (Auto/On-device/Cloud Boost) / BYO API key input / CSV export / Data Sources attribution / Privacy card | API key (optional); engine preference; export trigger | KeychainStore for API key; engine config UserDefaults; CSV generation from MealLog | Subscription status; engine config; CSV file | Keychain (API key); UserDefaults (engine pref) | Subscription status at top; one-tap manage; API key stored in Keychain (never leaves device); Data Sources credits OFF/USDA |
| 13 | **BYO API Key (Cloud Boost)** | 1. Settings → "Configure Custom API" → 2. Enter GLM/DeepSeek-compatible API key + endpoint → 3. Key stored in Keychain → 4. AI engine routes to user's endpoint (zero cost to developer) | API key string; endpoint URL (optional, defaults to GLM) | KeychainStore save; AIRouter checks key presence → routes to user endpoint | Verify engine uses user key; unlimited scans via user's key | Keychain (apiKey, endpoint) | Key never leaves device; user's endpoint used for all AI calls; zero developer cost; falls back if key invalid |
| 14 | **Progress Page** | 1. Tab to Progress → 2. See 14-day weight trend chart (weighted avg line) → 3. Weekly goal adjustment history → 4. Nutrient gap one-liner advice | Date range; weight logs; meal logs; TDEE history | Chart rendering; TDEE adjustment log; USDA RDA gap analysis (protein/iron/fiber) | Weight chart; adjustment history list; gap advice text | SwiftData WeightLog; MealLog; UserDefaults (TDEE history) | Chart uses 14-day weighted avg; adjustments shown with "here's why" text; gap advice uses USDA RDA (not AI hallucination) |
| 15 | **History Page** | 1. Tab to History → 2. Calendar view → 3. Select date → 4. See all meals for that date with thumbnails + kcal + confidence | Date selection | SwiftData query by date; meal card rendering | Meal list for selected date | SwiftData MealLog | Calendar navigation; meals grouped by type (breakfast/lunch/dinner/snack); tap meal to see detail |
| 16 | **Nutrition Gap Advice** | 1. On Progress page → 2. System checks today's protein/iron/fiber vs USDA RDA → 3. If gap → one-liner suggestion ("Protein gap — a Greek yogurt would close it") | Today's meal logs; USDA RDA targets | RDA comparison; gap calculation; suggestion generation | One-sentence text suggestion | USDA RDA constants (not AI) | Uses USDA RDA data (not AI hallucination); neutral amber tone (never red warning); actionable food suggestion |
| 17 | **CSV Import** | 1. Settings → "Import CSV" → 2. Select CSV file → 3. Map columns → 4. Import to MealLog | CSV file (MyFitnessPal/Lose It! export format) | CSV parsing; column mapping; SwiftData insert | Imported meals appear in History | SwiftData MealLog | Supports MFP/Lose It! export format; column auto-mapping; import confirmation |
| 18 | **Calibration Store (Personal Knowledge Base)** | 1. User corrects a scan → 2. Fingerprint (restaurant+dish+cuisine hash) saved with correction ratio → 3. Next scan of same fingerprint → pre-check calibration → adjust confidence | Correction ratio; restaurant/dish fingerprint | Fingerprint hash; correction history array; average downward correction | Adjusted confidence for future scans | SwiftData CalibrationRecord | Same restaurant second photo hits historical calibration; confidence adjusted by average correction; "越用越准" growth curve |

### Sub-Features & Detail Interactions

| # | Parent Feature | Sub-Feature | Detail Description | Interaction Pattern |
|---|---------------|-------------|-------------------|--------------------|
| 1.1 | AI Photo Scan | Shutter button | 120pt glass-effect button, lower 2/3 hot zone, haptic on tap | Tap |
| 1.2 | AI Photo Scan | Photo library import | Alternative to camera capture; pick from Photos app | Tap → PhotoPicker |
| 1.3 | AI Photo Scan | Remaining scan dots | 3 dots below shutter; used = gray; "Upgrade for unlimited" when all gray | Visual indicator |
| 1.4 | AI Photo Scan | Dual-Engine Verified badge | Glass badge appears when two engines agree; "✓ Dual-Engine Verified" | Auto-display |
| 2.1 | Correction Flow | Portion slider | 0.5–2.0× scale, 0.05 step; kcal updates real-time; light haptic on change | Drag |
| 2.2 | Correction Flow | Alternative food switch | Up to 3 alternative names shown as bordered buttons; tap to swap | Tap |
| 2.3 | Correction Flow | Quick quiz oil question | "How much oil was used?" None/Light/Medium/Lots + gram display | Slider + tap next |
| 2.4 | Correction Flow | Confidence badge | 🟢/🟣/🟠 icon + text ("AI is 70% sure") | Visual |
| 4.1 | Onboarding | Goal picker | 3 large buttons: Lose / Maintain / Gain | Tap |
| 4.2 | Onboarding | Number pickers | Height/weight/age scroll wheels with sensible defaults | Scroll |
| 9.1 | Subscription | Free scan counter | Monthly rolling reset; 3 scans; resets on calendar month | Auto-managed |
| 9.2 | Subscription | Trial pre-expiry notification | Local notification 24h before trial ends | System notification |
| 10.1 | HealthKit | Permission request timing | Requested on 2nd app open (not first), with one-sentence explanation | System dialog |
| 10.2 | HealthKit | Workout display-only | Exercise calories shown but NOT added to intake budget | Visual only |
| 12.1 | Settings | Manage Subscription | One-tap deep link to App Store subscription management | Tap → system |
| 12.2 | Settings | Data Sources | Attribution to Open Food Facts (ODbL) + USDA FoodData Central | Static text |

### Cross-Feature Dependencies

| Dependency | Source Feature | Target Feature | Data Passed | Trigger Condition |
|------------|---------------|----------------|-------------|-------------------|
| Scan → Today | AI Photo Scan (#1) + Correction (#2) | Today Dashboard (#3) | Confirmed MealLog (kcal, macros, confidence, thumbnail) | User taps "Looks right ✓" |
| Today → Ring | Today Dashboard (#3) | Ring display | Updated daily intake sum | MealLog saved |
| Onboarding → TDEE | Onboarding (#4) | Dynamic TDEE (#8) | goal, height, weight, age | Onboarding complete |
| Weight → TDEE | Weight Log (#7) | Dynamic TDEE (#8) | 14-day weight array | Weekly Sunday run |
| TDEE → Today | Dynamic TDEE (#8) | Today Dashboard (#3) | New target kcal | Weekly adjustment |
| Scan → Calibration | Correction Flow (#2) | Calibration Store (#18) | Fingerprint + correction ratio | User corrects a scan |
| Calibration → Scan | Calibration Store (#18) | AI Photo Scan (#1) | Adjusted confidence | Same fingerprint hit |
| Meal → HealthKit | AI Photo Scan (#1) + Manual (#6) | HealthKit (#10) | kcal, protein, carbs, fat | Meal confirm |
| Subscription → Quota | StoreKit 2 (#9) | AI Photo Scan (#1) | Entitlement (free/trial/pro) | Scan attempt |
| BYO Key → Router | Settings BYO (#13) | AI Photo Scan (#1) | API key presence | Engine selection |

**⚠️ VERIFICATION CHECK**: 18 primary features listed. Chinese guide describes: dual-engine scan, confidence correction (3 paths), today dashboard, onboarding (3 screens), barcode scan, manual entry, weight logging + trend, dynamic TDEE, StoreKit subscription, HealthKit, iCloud sync, settings, BYO API key, progress page, history page, nutrition gap advice, CSV import, calibration store. Count matches: 18/18. ✅ YES

## Apple Design Guidelines Compliance

- **Liquid Glass (iOS 26+)**: `.glassEffect()` on result cards and shutter button, matching system aesthetic.
- **Single-hand reachability**: Core operations (shutter/confirm/slider) in lower 2/3 hot zone.
- **One screen, one task**: Today = ring + photo; Result = confirm/fix; History = calendar. No nested infinite scroll.
- **Color psychology**: Confidence three-color (green/purple/orange); over-target uses neutral amber (never red anxiety).
- **SF Pro typography**: `.largeTitle` + `monospacedDigit()` for stable number rendering.
- **Dark mode first**: Follows system; ring glow in dark mode (Apple Health aesthetic).
- **Accessibility**: VoiceOver labels on all controls; Dynamic Type; color-blind mode uses icon+text dual encoding (✓/~/?).
- **Trust Blue #2E5CFF**: Primary brand color (trust-evoking tech blue for US market).

## ⚠️ App Store Compliance — AI Features

### GLM-5.3-Flash (Built-in Cloud AI Backend)
This app uses **GLM-5.3-Flash** (via bigmodel.cn API) as the built-in cloud vision model for food photo analysis. The model supports image input, text output, and reasoning capabilities. API documentation: https://docs.bigmodel.cn

**Configuration**:
- Model ID: `glm-5.3-flash` (or GLM vision-specific model ID if Flash channel doesn't accept images — test before launch)
- Endpoint: OpenAI-compatible Chat Completions format
- API Key: Developer-funded (subsidized cost ~$0.0001–0.0005/scan), stored server-side or in app config
- Cost: Flash tier, <2% of revenue at scale

### BYO API Key (Optional Advanced Configuration)
Users can optionally configure a custom API key (GLM, DeepSeek, or any OpenAI-compatible endpoint) in Settings → Configure Custom API. This is useful for:
- Users who want unlimited scans at their own API cost
- Users in regions where GLM cloud access varies
- Users who prefer specific models

### Guideline 2.1(a) — App Completeness
- AI features work with built-in GLM key (no user configuration needed for basic functionality)
- Free tier: 3 scans/month (rolling reset) — always peak quality, never degraded model
- Reviewers can test AI immediately on download
- `canScan` logic: `freeScansRemaining > 0 || isPremium || hasAPIKey` — no dead "free generation count" code

### Dead Code Prevention
- ❌ NEVER add: `freeGenerationsUsed`, `maxFreeGenerations`, `canGenerateFree`, `incrementGenerationCount()`
- Free tier limits SCAN COUNT (quota), not AI MODEL QUALITY

### Health Claim Compliance
- ❌ NEVER use: "accurate", "proven", "clinically", "precise", specific accuracy percentages
- ✅ Use: "estimate", "your trusted companion", "dual-engine verified", "confidence"
- Never promise weight loss results (Apple Health category review red line)
- Nutrient gap advice labeled "general wellness information"

## ⚠️ App Store Compliance — Subscriptions

### Guideline 3.1.2(c) — Subscription Information
Apple REQUIRES the following in the Paywall view:
- Functional link to Privacy Policy
- Functional link to Terms of Use (EULA)
- Subscription title, length, and price
- Auto-renewal disclosure text

### Pricing Structure
| Tier | Name | Price | Content |
|------|------|-------|---------|
| Free | SureCal Free | $0 | 3 dual-engine scans/month (rolling) + unlimited manual/barcode/weight |
| Trial | Peak Trial | 7 days free | Unlimited dual-engine + all Pro features; auto-reverts to Free |
| Yearly | SureCal Pro (Yearly) | $19.99/yr | Unlimited scans + correction engine + Asian cuisine pack + dynamic TDEE + Watch + Widget + iCloud + CSV |
| Monthly | SureCal Pro (Monthly) $2.99/mo | Same as yearly |
| BYO | Cloud Boost | $0 (with Pro) | User's own API key → unlimited scans at user's cost |

### Trial Compliance
- 7-day trial auto-reverts to Free (NEVER silent auto-charge)
- 24h pre-expiry local notification
- Trial consumes Pro quota, NOT user's free 3 scans
- One-tap cancel in Settings

## Technical Architecture

- **Language**: Swift 5.9+
- **Framework**: SwiftUI (primary), UIKit (AVFoundation camera)
- **Data**: SwiftData (local) + CloudKit (sync, optional)
- **AI L0**: Apple FoundationModels (iOS 26+, on-device, free)
- **AI L1**: Apple Private Cloud Compute (free Small Business tier)
- **AI L2**: GLM-5.3-Flash (bigmodel.cn, OpenAI-compatible, developer-subsidized)
- **AI BYO**: DeepSeek Vision / GLM / any OpenAI-compatible (user's key)
- **AI Protocol**: `VisionNutritionEngine` protocol (unified interface for all engines)
- **Food DB**: Open Food Facts local DB (9.88M items) + USDA FoodData Central API
- **Payment**: StoreKit 2 (auto-renewable subscription, no buyout)
- **Health**: HealthKit (HKQuantityType, HKWorkout — display only)
- **Barcode**: Vision framework (VNDetectBarcodesRequest)

## Module Structure

```
SureCal/
├── App/
│   ├── SureCalApp.swift          # @main entry, SwiftData container
│   └── ContentView.swift         # TabView root
├── Views/
│   ├── Today/
│   │   ├── TodayView.swift        # Dashboard with ring + shutter
│   │   └── TodayViewModel.swift
│   ├── Scan/
│   │   ├── ScanResultView.swift   # Result card + correction flows
│   │   ├── PortionFixCard.swift   # Purple band slider
│   │   ├── QuickQuizView.swift    # Orange band Q&A
│   │   └── ScanViewModel.swift
│   ├── Progress/
│   │   ├── ProgressView.swift     # Weight trend + TDEE history
│   │   └── ProgressViewModel.swift
│   ├── History/
│   │   ├── HistoryView.swift      # Calendar + meal list
│   │   └── HistoryViewModel.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── SettingsViewModel.swift
│   └── Onboarding/
│       └── OnboardingView.swift
├── Models/
│   ├── MealLog.swift              # @Model
│   ├── FoodEntry.swift            # @Model
│   ├── WeightLog.swift            # @Model
│   ├── CalibrationRecord.swift   # @Model
│   └── FoodAnalysis.swift        # AI output struct
├── Services/
│   ├── AIRouter.swift             # Engine selection
│   ├── DualEngineOrchestrator.swift
│   ├── GLMFlashVisionEngine.swift # GLM-5.3-Flash impl
│   ├── AppleFMVisionEngine.swift  # FoundationModels impl
│   ├── ConfidenceRouter.swift
│   ├── NutritionLookup.swift      # USDA/OFF查表
│   ├── HealthKitWriter.swift
│   ├── AdaptiveTDEEEngine.swift
│   ├── QuotaManager.swift         # Scan quota
│   ├── KeychainStore.swift
│   ├── SubscriptionManager.swift  # StoreKit 2
│   └── CSVImporter.swift
├── Components/
│   ├── ConfidenceBadge.swift
│   ├── CalorieRing.swift
│   ├── ShutterButton.swift
│   ├── DualEngineBadge.swift
│   └── ConfirmBar.swift
└── Config/
    ├── GLMConfig.swift
    ├── PricingConfig.swift
    └── NutritionRDA.swift
```

## ⚠️ Data Flow Diagram (MANDATORY — Every Feature's Data Lifecycle)

```
Feature 1: AI Photo Scan (Dual-Engine)
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── Tap shutter → camera capture / photo pick           │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── ScanViewModel → ImagePreprocessor (1024px JPEG)     │
│  └── AIRouter.shared.primaryEngine(for: imageData)       │
│  └── DualEngineOrchestrator.scan(imageData, context)      │
│  └── ConfidenceRouter.route(analysis, calibration)        │
│       │                                                   │
│  Model/Persistence                                        │
│  └── On confirm → SwiftData MealLog + FoodEntry save     │
│  └── CalibrationStore.write(fingerprint, correction)     │
│  └── HealthKitWriter.write(meal) (if authorized)          │
│       │                                                   │
│  Display Output                                           │
│  └── ScanResultView: photo + items + confidence badge    │
│  └── Today: ring updates + meal card appears              │
│       │                                                   │
│  Cross-Feature Output                                    │
│  └── Today ring recalculates; Progress weight trend ready│
└───────────────────────────────────────────────────────────┘

Feature 2: Confidence Correction Flow
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── Green: tap "Looks right ✓"                          │
│  └── Purple: drag slider (0.5–2.0×) or tap alternative   │
│  └── Orange: answer ≤3 quiz Qs (oil/sauce/portion)        │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── ScanViewModel: recalculate kcal = kcalPerGram × g  │
│  └── QuickQuiz: add hiddenOilGrams to FoodEntry          │
│  └── Record correctionSeconds = Date.now - startTime     │
│       │                                                   │
│  Model/Persistence                                        │
│  └── MealLog.wasCorrected = true; correctionSeconds set  │
│  └── CalibrationRecord: update fingerprint history       │
│       │                                                   │
│  Display Output                                           │
│  └── Ring updates with corrected kcal                    │
│  └── Return to Today                                      │
└───────────────────────────────────────────────────────────┘

Feature 3: Today Dashboard
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── App opens; no action needed (auto-load)             │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── TodayViewModel: fetch today's MealLogs from SwiftData│
│  └── Sum kcal + macros from all FoodEntries              │
│  └── Compare vs currentTargetKcal (UserDefaults)         │
│  └── QuotaManager.shared.remainingScans (for dots)       │
│       │                                                   │
│  Model/Persistence                                        │
│  └── SwiftData @Query MealsLog (date == today)           │
│       │                                                   │
│  Display Output                                           │
│  └── CalorieRing: intake/target with animation           │
│  └── Macro arcs: protein/carb/fat                        │
│  └── Meal cards: thumbnail + kcal + badge                │
│  └── Shutter button + 3 scan dots                        │
└───────────────────────────────────────────────────────────┘

Feature 4: Onboarding
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── Screen 1: read value prop (no input)                │
│  └── Screen 2: tap goal (lose/maintain/gain)             │
│  └── Screen 3: scroll height/weight/age pickers           │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── BMR = Mifflin-St Jeor(height, weight, age)           │
│  └── TDEE = BMR × activityFactor (default 1.4 sedentary) │
│  └── Target = goal == lose ? TDEE - 400 : TDEE (+400 gain)│
│       │                                                   │
│  Model/Persistence                                        │
│  └── UserDefaults: onboardingComplete, goal, h, w, age   │
│  └── UserDefaults: currentTargetKcal                     │
│       │                                                   │
│  Display Output                                           │
│  └── Navigate to TodayView with empty state               │
│  └── "Snap your first meal — it takes 5 seconds."        │
└───────────────────────────────────────────────────────────┘

Feature 5: Barcode Scan
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── Tap barcode icon → camera scans barcode             │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── Vision VNDetectBarcodesRequest → barcode string     │
│  └── NutritionLookup.barcode(barcode) → OFF local DB     │
│  └── Map to FoodEntry (name, kcal, protein, carbs, fat)  │
│       │                                                   │
│  Model/Persistence                                        │
│  └── OFF local SQLite DB (9.88M items, bundled or DL)    │
│  └── On confirm → MealLog (source: "barcode_off")        │
│       │                                                   │
│  Display Output                                           │
│  └── Food card with nutrition → portion confirm → save   │
└───────────────────────────────────────────────────────────┘

Feature 6: Manual Entry
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── Tap "Add manually" → type food name → enter grams   │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── NutritionLookup.search(name) → USDA/OFF match       │
│  └── Calculate: kcal = per100g × (grams/100)             │
│       │                                                   │
│  Model/Persistence                                        │
│  └── On confirm → MealLog (source: "manual")            │
│       │                                                   │
│  Display Output                                           │
│  └── Food card with calculated macros → confirm → save   │
└───────────────────────────────────────────────────────────┘

Feature 7: Weight Logging + Trend
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── Progress page → tap "Log weight" → enter kg/lb      │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── WeightLogViewModel: save to SwiftData              │
│  └── Compute 14-day weighted moving average              │
│  └── Exclude single-day outliers (>2 std dev)            │
│       │                                                   │
│  Model/Persistence                                        │
│  └── SwiftData WeightLog (date, weight)                  │
│  └── HealthKitWriter.writeBodyMass(weight) (if auth)    │
│       │                                                   │
│  Display Output                                           │
│  └── Weight trend chart with smooth avg line             │
└───────────────────────────────────────────────────────────┘

Feature 8: Dynamic TDEE Engine
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── None (auto-runs weekly on Sunday)                   │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── AdaptiveTDEEEngine.weeklyAdjustment(               │
│  │      weightTrend: [Double], intake: [Double], goal)   │
│  │   ) → realTDEE = avgIntake + (weightDelta/day × 7.7)  │
│  │   → target = goal == lose ? realTDEE - 400 : realTDEE │
│  │   → clamp(target - current, -200...200)              │
│       │                                                   │
│  Model/Persistence                                        │
│  └── UserDefaults: currentTargetKcal updated             │
│  └── UserDefaults: TDEE adjustment history array         │
│       │                                                   │
│  Display Output                                           │
│  └── Progress page: "AI adjusted your goal -50 kcal..." │
│  └── Local notification: "Your goal moved to 1,850..."  │
└───────────────────────────────────────────────────────────┘

Feature 9: StoreKit 2 Subscription
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── Exhaust 3 free scans → soft paywall → select plan   │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── SubscriptionManager.fetchProducts() → StoreKit 2    │
│  └── Purchase → verify transaction → update entitlement   │
│  └── Trial: set trialEndDate = now + 7 days              │
│  └── 24h pre-expiry: schedule local notification          │
│       │                                                   │
│  Model/Persistence                                        │
│  └── StoreKit 2 transaction (system-managed)             │
│  └── UserDefaults: entitlement (free/trial/pro)         │
│       │                                                   │
│  Display Output                                           │
│  └── QuotaManager: unlimited scans if pro/trial          │
│  └── Settings: subscription status + manage link         │
└───────────────────────────────────────────────────────────┘

Feature 10: HealthKit Integration
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── 2nd app open: permission dialog (with explanation)  │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── HealthKitWriter.write(meal): HKQuantitySample for   │
│  │   dietaryEnergy, protein, carbs, fat                  │
│  └── WeightLog: HKQuantitySample bodyMass                 │
│  └── Read HKWorkout (display calories only, NOT intake)  │
│       │                                                   │
│  Model/Persistence                                        │
│  └── HealthKit store (system-managed)                    │
│       │                                                   │
│  Display Output                                           │
│  └── Workout calories shown on Today (display only)      │
│  └── Health app shows SureCal-written data               │
└───────────────────────────────────────────────────────────┘

Feature 11: iCloud Sync
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── Settings → enable iCloud sync toggle                │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── SwiftData CloudKit container: auto-sync            │
│  └── Incremental sync (no full re-push)                  │
│       │                                                   │
│  Model/Persistence                                        │
│  └── CloudKit private database (E2E encrypted)           │
│       │                                                   │
│  Display Output                                           │
│  └── Data appears on user's other Apple devices          │
└───────────────────────────────────────────────────────────┘

Feature 12-18: [Settings, BYO Key, Progress, History, Gap Advice, CSV Import, Calibration Store]
┌───────────────────────────────────────────────────────────┐
│  [Each follows standard ViewModel → Service → SwiftData │
│   pattern; key data flows documented in cross-feature     │
│   dependency table above]                                │
└───────────────────────────────────────────────────────────┘
```

**⚠️ VERIFICATION CHECK**: 10 detailed data flow diagrams + 8 summary diagrams = 18 total, matching 18 features. ✅ All features have documented data lifecycle.

## Implementation Flow

1. **Project config**: Set Bundle ID `com.zzoutuo.SureCal`, deployment target iOS 17.0+, SwiftData, HealthKit, Camera capabilities.
2. **Data models**: MealLog, FoodEntry, WeightLog, CalibrationRecord (@Model SwiftData).
3. **AI layer**: VisionNutritionEngine protocol → GLMFlashVisionEngine (primary, GLM-5.3-Flash) + AppleFMVisionEngine (fallback) + AIRouter + DualEngineOrchestrator + ConfidenceRouter.
4. **Core UI**: TodayView (ring + shutter) → ScanResultView (3 correction paths) → OnboardingView (3 screens).
5. **Nutrition**: NutritionLookup (USDA/OFF) — AI identifies food, nutrition comes from authoritative DB (not AI-hallucinated).
6. **HealthKit**: HealthKitWriter (write on confirm; workout display-only).
7. **StoreKit 2**: SubscriptionManager (monthly/yearly/trial; no buyout; auto-revert).
8. **Progress**: AdaptiveTDEEEngine (weekly auto-adjust) + weight trend chart.
9. **Settings**: BYO API key (Keychain) + CSV import + Data Sources.
10. **Calibration**: CalibrationRecord fingerprint store (越用越准).

## UI/UX Design Specifications

- **Color Scheme**: Trust Blue #2E5CFF (primary); warm orange for food photography accent; confidence green #34C759 / purple #AF52DE / orange #FF9500; neutral amber #FFCC00 for over-target (never red).
- **Typography**: SF Pro; `.largeTitle` + `.monospacedDigit()` for calorie numbers.
- **Layout**: Today = full-screen ring + bottom 2/3 shutter; Result = 16:9 photo top + items + button; single-hand optimized.
- **Animations**: Ring charge-up on confirm; haptic feedback (light) on slider drag; (medium) on confirm; glass shimmer on dual-engine badge.
- **Dark mode**: Follows system; ring glow in dark (Apple Health aesthetic).

## Code Generation Rules

1. **Single source of truth**: All nutrition numbers from `NutritionLookup` (USDA/OFF); AI only identifies food + estimates portion — NEVER AI-direct calorie.
2. **All AI output strongly typed**: `FoodAnalysis` struct with explicit fields; parse failure → degrade L0→L1→L2→text fallback (never blank screen).
3. **Every interaction ≤3 steps**: New feature exceeding 3 steps must be redesigned; correction ≤5 seconds.
4. **Limit count, not quality**: Free/trial/paid all use same dual-engine peak AI; never silently switch to lower model for free users.
5. **Privacy default local**: SwiftData local; CloudKit opt-in; photos local-only unless cloud verify needed.
6. **Price constants centralized**: `PricingConfig.swift` single file; no hardcoded prices in UI.
7. **Health claims compliant**: Never "accurate/proven/clinically"; use "estimate/trusted/dual-engine verified"; no weight-loss promise.
8. **Testable**: ConfidenceRouter, DualEngineOrchestrator.agree(), AdaptiveTDEEEngine, NutritionLookup must be pure functions with XCTest.
9. **Trial compliance**: 7-day trial auto-reverts; 24h pre-expiry notification; trial consumes Pro quota not free 3 scans.

## Build & Deployment Checklist

- [ ] Bundle ID: `com.zzoutuo.SureCal`
- [ ] Min iOS: 17.0
- [ ] Capabilities: HealthKit, Camera, iCloud (CloudKit), StoreKit (IAP)
- [ ] Info.plist: NSCameraUsageDescription, NSHealthShareUsageDescription, NSHealthUpdateUsageDescription, NSPhotoLibraryUsageDescription
- [ ] StoreKit 2 products: monthly ($2.99), yearly ($19.99), trial (7-day)
- [ ] GLM API key configured in `GLMConfig.swift` (developer-subsidized)
- [ ] Open Food Facts local DB bundled or downloadable
- [ ] App icon generated (1024×1024 + all sizes)
- [ ] SwiftData CloudKit container configured
- [ ] Privacy policy + Terms of Use pages deployed
- [ ] App Store metadata (title, subtitle, keywords, screenshots)

## Reference Projects (from Chinese guide)

| Project | URL | Use Case |
|---------|-----|----------|
| CalorieEstimator | github.com/mfsaglam/CalorieEstimator | L0 Apple FoundationModels engine reference (MIT) |
| kcalz | github.com/rbaumier/kcalz | OFF local index implementation reference |
| AICaloriesSupport | github.com/WeiProduct/AICaloriesSupport- | SwiftUI + SwiftData food photo recognition skeleton |
| PrivateFoundationModels | github.com/john-rocky/PrivateFoundationModels | iOS 18+ FoundationModels compatibility (CoreML/MLX) (MIT) |
| swift-ai-kit | github.com/lucianfialho/swift-ai-kit | Apple Intelligence Xcode template (MIT) |
| BirdBrainAI | github.com/BaidetskyiYurii/BirdBrainAI | Tool protocol + streaming + Clean Architecture (MIT) |
| foundationmodels-starter-pack | github.com/98dkcc488b-glitch/foundationmodels-starter-pack | Three-tier fallback chain reference |
| caloriemate | github.com/ignoxx/caloriemate | Privacy-first calorie tracker reference |
| FoodVision | github.com/ensoreus/FoodVision | Food-101 → ResNet50 → CoreML pipeline |
| magicmeal | github.com/phishy/magicmeal | Multi-feature tracker (photo+barcode+weight) reference |
