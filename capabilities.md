# SureCal — 配置文档

生成时间：2026-09-15

---

## 一、⚠️ 手动配置（增强功能 — 不配置不影响基本使用）

> **重要说明**：App 核心功能（AI 拍照识别、卡路里环、手动记录、条码扫描、体重趋势、HealthKit）**下载即可用，零配置**。GLM-5.3-Flash AI 引擎已内嵌开发者 Key，开箱即用。以下为需要你手动完成的增强/上架配置。

### 🔵 IAP StoreKit 配置（订阅购买必需）

**影响功能**：不创建 IAP 产品，用户无法完成订阅购买（免费层仍完整可用）

**配置步骤**：
1. 打开 [App Store Connect](https://appstoreconnect.apple.com) → 我的 App → 创建 App 记录（Bundle ID: `com.zzoutuo.SureCal`）
2. 进入 **Features** → **In-App Purchases** → 点击 **"+"** → 选择 **Auto-Renewable Subscription** → 创建订阅组 `SureCal Pro`
3. 在组内创建两个订阅产品：

| 产品 | Reference Name | Product ID | 价格 |
|------|---------------|-----------|------|
| 月付 | SureCal Pro Monthly | `com.zzoutuo.SureCal.pro.monthly` | $2.99/月 |
| 年付 | SureCal Pro Yearly | `com.zzoutuo.SureCal.pro.yearly` | $19.99/年 |

4. 每个产品填写（从 `price.md` 复制）：
   - Display Name: `SureCal Pro Monthly` / `SureCal Pro Yearly`
   - Description: `Unlimited dual-engine scans and all Pro features`
5. 为两个产品添加 **Introductory Offer** → **Free Trial** → 时长 **7 天**（这是"巅峰试用"）
6. 产品创建后等待 Apple 审核（通常 1-2 小时生效）
7. 本地测试：Xcode → File → New → File → StoreKit Configuration File，按上表添加产品即可沙盒测试
8. 验证：App → Settings → Upgrade to Pro → 确认产品加载并完成一笔沙盒购买 → "Restore Purchases" 可恢复

---

### 🟡 Capabilities 增强配置 — iCloud CloudKit 容器

**增强功能**：用户开启 Settings → iCloud Sync 后跨设备同步数据
**不配置的影响**：App 默认纯本地存储，完全正常使用，仅无跨设备同步
**当前状态**：代码已实现优雅降级，无需配置即可正常使用

**已自动配置部分**：
- ✅ `SureCal.entitlements` 已声明 CloudKit 服务与容器 `iCloud.com.zzoutuo.SureCal`
- ✅ SwiftData 容器已按开关动态启用/禁用 CloudKit
- ✅ Xcode 自动签名已配置（Team: JP4TN5PTS3）

**如需启用增强功能，请手动配置**：
1. 打开 [Apple Developer](https://developer.apple.com) → **Certificates, Identifiers & Profiles** → **Identifiers**
2. 找到 `com.zzoutuo.SureCal`（如不存在则先在 App Store Connect 创建 App 记录后同步）→ 点击编辑
3. 勾选 **iCloud**（Include CloudKit support）→ **Edit** → 添加容器 `iCloud.com.zzoutuo.SureCal`
4. ⚠️ 配置完成后重新 Build 验证：Settings → iCloud Sync 开启后多设备可见数据

---

### 🟢 App Store 上架前置（3 项）

**影响功能**：上架必需

1. **更新 Landing Page 的 App Store ID**：在 App Store Connect 创建 App 后，复制 App Information 页的 **Apple ID**（数字），替换 [docs/index.html](docs/index.html) 中两处 `[APP_STORE_ID]` 占位符，然后 `git add docs/index.html && git commit -m "Set App Store ID" && git push`（页面按钮自动从 "Coming Soon" 变为 "Download"）
2. **App Review Information**：在 App Store Connect → App Review Information 的 **Notes** 字段粘贴 `keytext.md` 末尾 **Review Notes** 段落（含 HealthKit 合规声明、订阅测试说明、AI 引擎说明）
3. **法律链接**：App Store Connect → App Privacy 与 EULA 字段填写：
   - Privacy Policy: `https://asunnyboy861.github.io/SureCal/privacy.html`
   - Terms of Use: `https://asunnyboy861.github.io/SureCal/terms.html`
   - Support: `https://asunnyboy861.github.io/SureCal/support.html`

---

### 💡 使用提示（非开发者配置，App 内操作即可）

**BYO API Key（Cloud Boost）**：App 默认使用内嵌 GLM-5.3-Flash 引擎（免费额度 3 次/月，Pro 无限）。Pro 用户可在 **Settings → AI Engine → Custom API** 填入自己的任何 OpenAI 兼容 Key（GLM/DeepSeek/OpenAI 等），即按用户自己账户无限次扫描，Key 仅存本机 Keychain。这是用户操作，非开发者配置。

---

## 二、✅ 自动配置记录（已由系统完成，无需操作）

### Capabilities 自动配置

| Capability | 说明 | 状态 |
|------------|------|------|
| Camera + Photo Library | Info.plist 权限描述已配置（pbxproj INFOPLIST_KEY） | ✅ 已配置 |
| HealthKit | entitlement + 权限描述已配置，UI 符合 Guideline 2.5.1（图标/标题/Learn More/页脚） | ✅ 已配置 |
| iCloud CloudKit entitlement | 容器声明已写入 entitlements | ✅ 已配置（容器创建待门户） |
| In-App Purchase | StoreKit 2 无需 entitlement，代码已集成 | ✅ 已配置 |
| Local Notifications | 试用到期前 24h 提醒 + 每周目标调整通知 | ✅ 已配置 |
| Outgoing Network | HTTPS 出站（反馈后端 + GLM API + OFF API），默认允许 | ✅ 已配置 |

### 后端服务

| 服务 | 说明 | 状态 |
|------|------|------|
| 联系客服后端 | Cloudflare Workers：`https://feedback-board.iocompile67692.workers.dev/api/feedback` | ✅ 已部署并对接 |
| GLM-5.3-Flash API | open.bigmodel.cn，Key 已内嵌 `GLMConfig.swift`，文本/视觉/JSON 三项实测通过 | ✅ 已验证 |
| Open Food Facts API | 条码在线查询 | ✅ 已对接 |

### 代码生成

| 模块 | 说明 | 状态 |
|------|------|------|
| 核心功能 | 18/18 功能，MVVM，SwiftData + 双引擎互验 + 置信度路由 | ✅ 已完成 |
| ContactSupportView | 7 主题磁贴 + 5 必填字段 + 后端对接 + 隐私文案 | ✅ 已完成 |
| PurchaseManager (SubscriptionManager) | StoreKit 2 双订阅 + 7 天试用 + currentEntitlement 检查 | ✅ 已完成 |
| PaywallView | 价格展示 + 隐私/条款链接 + 自动续订披露 | ✅ 已完成 |
| AI 引擎 | GLM 内嵌 + BYO Key（Keychain）+ DualEngineOrchestrator | ✅ 已完成 |
| QA 迭代 | improvement_plan_1.md，1 轮迭代修复 10 项 | ✅ 已完成 |
| 单元测试 | 11/11 通过（ConfidenceRouter/互验/TDEE/CSV/GLM解析） | ✅ 已通过 |
| App 图标 | Agnes Image 生成，无 alpha，全尺寸 | ✅ 已完成 |

### 部署

| 项目 | 说明 | 状态 |
|------|------|------|
| GitHub 仓库 | https://github.com/asunnyboy861/SureCal（keytext*.md/.env 已 gitignore） | ✅ 已推送 |
| GitHub Pages | Landing + Support + Privacy + Terms 全部 200 | ✅ 已上线 |
| App Store 元数据 | keytext.md（15 项验证通过）+ keytext_inventory.md | ✅ 已生成 |

---

## 三、能力检测详情

> 以下为 PHASE 2 原始检测数据，其余内容已重组到上方 Section 一、二。

### Analysis

基于 us.md 与中文指南关键词扫描：拍照/相机/照片 → Camera+Photo Library；健康/HealthKit → HealthKit；订阅/购买/StoreKit → IAP；iCloud/同步/CloudKit → iCloud（可选）；通知/提醒 → Local Notifications；条码 → Camera(Vision)。

### No Configuration Needed

- Sign in with Apple — 无账号设计
- Location Services / Siri — 未使用
- Apple Watch / Widget — Pro 后续功能，本版未实现（元数据未提及）

### Verification

- 构建验证：iPhone 16 (iOS 26.4) ✅ BUILD SUCCEEDED；iPad Pro 13-inch (M5) ✅ BUILD SUCCEEDED
- 单元测试：11/11 通过
- 模拟器实机：Onboarding 与 Today 页截图验证通过
