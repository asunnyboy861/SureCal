# improvement_plan_1.md — SureCal QA Iteration 1

## Phase A Issues Found & Fixes Implemented

| Issue ID | Description | Severity | Code Changes | Status |
|----------|-------------|----------|--------------|--------|
| ISSUE-001 | Missing `import Combine` in QuotaManager / DualEngineOrchestrator / HealthKitWriter — ObservableObject/@Published failed to compile | Critical | Added `import Combine` to all 3 service files | Implemented ✅ |
| ISSUE-002 | CameraSession used invalid `CheckedContinuation` init — capture callback broken | Critical | Replaced with `captureCompletion` closure pattern; marked delegate methods `nonisolated` | Implemented ✅ |
| ISSUE-003 | Wrong HealthKit identifiers: `.dietaryEnergy` → `.dietaryEnergyConsumed`; wrong `HKQuantity`/`HKUnit` construction | Critical | Rewrote HealthKitWriter with `HKQuantity(unit:doubleValue:)`, `HKUnit.gram()`, `.gramUnit(with: .kilo)` | Implemented ✅ |
| ISSUE-004 | Portion slider mutated local copy only — corrections never reached save (broken data flow Feature #2) | Critical | FoodResultRow now receives `Binding<FoodAnalysisItem>` and applies scale factors to live item | Implemented ✅ |
| ISSUE-005 | `if let errorText` shadowed @State as immutable — "Scan Again" button couldn't reset state | Major | Renamed shadow binding to `message` | Implemented ✅ |
| ISSUE-006 | QuotaManager init accessed `self` before all stored properties initialized | Major | Rewrote init with local variables first | Implemented ✅ |
| ISSUE-007 | BMR test expectation arithmetic wrong (1725 vs correct 1698.75) | Minor | Fixed test to `1698.75` | Implemented ✅ |
| ISSUE-008 | `Product.SubscriptionOffer.displayPeriodLength` not available in current SDK | Major | Trial caption uses `paymentMode == .freeTrial` check with static 7-day text | Implemented ✅ |
| ISSUE-009 | Paywall legal links (COMPLIANCE-PAYWALL) missing | Major (compliance) | Privacy Policy + Terms of Use links + auto-renewal disclosure added below Subscribe area | Implemented ✅ (initial generation) |
| ISSUE-010 | HealthKit UI identification (COMPLIANCE-HK) | Major (compliance) | Section header "Apple Health (HealthKit)" + `heart.text.square.fill` icon + HealthKit Integration row + Learn More → HealthKitInfoView + footer disclosure | Implemented ✅ (initial generation) |

## Verification

- `xcodebuild build` (iPhone 16 simulator): **BUILD SUCCEEDED**
- `xcodebuild test -only-testing:SureCalTests`: **TEST SUCCEEDED — 11/11 tests passed**
- App launched on simulator: Onboarding screen 1 renders correctly (value prop + transparent pricing + Get Started)
- Today page after onboarding: calorie ring, 120pt shutter, 3 scan dots, empty state, 4 tabs — all render correctly
- Hardcoded version scan: 0 occurrences (dynamic `Bundle.main.infoDictionary`)
- TODO/FIXME/stub scan: 0 occurrences
- Free-generation counting scan: 0 occurrences (quota counts scan quantity, never degrades model quality)

## Scores After Iteration 1

- Usability: 5/5 (was 4/5) — 3-screen onboarding, ≤3 taps to log, slider fix restored 3-second correction
- UI Consistency: 5/5 (was 4/5) — Trust Blue tint inherited across all screens, semantic colors only
- Feature Completeness: 5/5 (was 4/5) — 18/18 features implemented, slider data flow fixed
- Download-to-Use: 5/5 (was 4/5) — built-in GLM engine works with zero configuration
- Competitive Level: 4/5 — dual-engine verify badge + confidence routing + calibration store are category differentiators
- Contact Support: 5/5 — 7 subject tiles + required fields + backend + privacy microcopy + success/error states
- Accessibility: 4/5 — VoiceOver labels on core controls, Dynamic Type fonts, color+icon dual encoding for confidence

EXIT CRITERIA: ALL MET (0 Critical, 0 Major remaining, build + tests green)
