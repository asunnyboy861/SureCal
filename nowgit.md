# Git Repositories

## Main App (iOS Application)

| Item | Value |
|------|-------|
| **Repository Name** | SureCal |
| **Git URL** | git@github.com:asunnyboy861/SureCal.git |
| **Repo URL** | https://github.com/asunnyboy861/SureCal |
| **Visibility** | Public |
| **Primary Language** | Swift |
| **GitHub Pages** | ✅ **ENABLED** (from `/docs` folder) |

## Security Note — GLM API Key Handling

The GLM-5.3-Flash API key is **NOT stored in this repository**. `SureCal/Services/GLMConfig.swift` reads the key at runtime from a bundled `GLMSecret.txt` file that is **gitignored** (`SureCal/GLMSecret.txt`, kept only on the developer machine and packaged into release builds). Fresh clones build successfully, but the built-in AI engine is disabled until the developer adds their local `GLMSecret.txt` — users can always fall back to BYO API key (Settings - AI Engine, stored in Keychain). History was rewritten with git-filter-repo and the repository was force-pushed to purge an earlier accidental exposure; the key should still be rotated on bigmodel.cn as a precaution.

## Build & Test Verification (this commit)

| Check | Result |
|-------|--------|
| iPhone 16 (iOS 26.4) build | ✅ BUILD SUCCEEDED |
| iPhone 16 unit tests | ✅ 11/11 passed |
| iPhone 16 run test | ✅ Onboarding + Today verified via screenshots |
| iPad Pro 13-inch (M5) build | ✅ BUILD SUCCEEDED |
| iPad Pro 13-inch (M5) run test | ✅ Launched, layout renders |
| GLM-5.3-Flash API | ✅ Text / Vision / JSON verified live |

## Policy Pages (Deployed from Main Repository /docs)

| Page | URL | Status |
|------|-----|--------|
| Landing Page | https://asunnyboy861.github.io/SureCal/ | ✅ Active |
| Support | https://asunnyboy861.github.io/SureCal/support.html | ✅ Active |
| Privacy Policy | https://asunnyboy861.github.io/SureCal/privacy.html | ✅ Active |
| Terms of Use | https://asunnyboy861.github.io/SureCal/terms.html | ✅ Active |

## Repository Structure

```
SureCal/
├── SureCal.xcodeproj/            # Xcode Project
├── SureCal/                      # iOS App Source Code
│   ├── SureCalApp.swift          # @main entry
│   ├── ContentView.swift         # TabView root + TDEE weekly runner
│   ├── Models/                   # SwiftData models + FoodAnalysis DTO
│   ├── Services/                 # GLM engine, AI router, dual-engine, quota, IAP, HealthKit, TDEE, CSV
│   ├── Views/                    # Today / Scan / Progress / History / Settings / Onboarding
│   ├── Components/               # CalorieRing, ShutterButton, ConfidenceBadge, DualEngineBadge
│   ├── Config/                   # NutritionRDA
│   ├── GLMConfig.swift           # endpoint/model/pricing constants (GLM key embedded)
│   └── Assets.xcassets/          # AppIcon (Agnes-generated) + AccentColor
├── SureCalTests/                 # XCTest unit tests (11)
├── SureCalUITests/               # UI test target
├── us.md / price.md / capabilities.md / icon.md
├── improvement_plan_1.md         # QA iteration record
├── keytext.md                    # ⚠️ EXCLUDED from repo (.gitignore — confidential ASO strategy)
├── COMPETITOR_REPORT.md          # ⚠️ EXCLUDED from repo (.gitignore)
├── .env                          # ⚠️ EXCLUDED from repo (.gitignore)
└── docs/                         # Policy Pages (GitHub Pages source) — PHASE 7
```
