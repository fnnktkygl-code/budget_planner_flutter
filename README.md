# 💎 AuraBudget Pro (Her Budget) — Open Banking & AI Financial Planner

[![Live Website](https://img.shields.io/badge/Live%20Website-aurabudgetpro.vercel.app-059669?style=for-the-badge&logo=vercel&logoColor=white)](https://aurabudgetpro.vercel.app)
[![Flutter](https://img.shields.io/badge/Flutter-v3.11+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/Riverpod-v2.6.1-blueviolet?style=for-the-badge)](https://riverpod.dev)
[![Vercel](https://img.shields.io/badge/Vercel-Deployed-black?style=for-the-badge&logo=vercel)](https://aurabudgetpro.vercel.app)

> **AuraBudget Pro** (Her Budget) is a cross-platform personal finance management suite built with **Flutter** and **Riverpod**. It combines **TrueLayer Open Banking API** live bank account integration with an **AI Payslip PDF Parser & Salary Audit Engine** to track net pay variations, monthly budget caps, and long-term savings goals.

🌐 **Live Demo Website**: [https://aurabudgetpro.vercel.app](https://aurabudgetpro.vercel.app) *(also accessible via [https://aurabudget-pro.vercel.app](https://aurabudget-pro.vercel.app))*

---

## 🌟 Key Features

### 🏦 Open Banking Ingestion (TrueLayer API)
- Real-time bank account sync and transaction classification.
- Secure OAuth2 authentication flow via `webview_flutter` & TrueLayer sandboxed/live endpoints.
- Auto-categorization of expenses (Rent, Groceries, Subscriptions, Savings).

### 📄 AI Payslip Parsing & Salary Audit
- Native PDF ingestion (`pdfx` & `file_picker`) for extracting monthly French/European payslips.
- Automatic extraction of gross-to-net tax ratios, RTT deductions, variable bonuses, and net pay history.
- Dynamic trend chart generator with interactive tooltip popovers and pinch-to-zoom (`InteractiveViewer`).

### 📊 Financial Dashboard & Trend Analysis
- Real-time net monthly income vs. expenditure curves.
- Multi-month historical balance cards with tax deduction breakdowns.
- Customizable budget targets and threshold alerts.

### 🔒 Enterprise Privacy & Security
- Encrypted key-value persistence using `flutter_secure_storage`.
- Zero client-side data leaks; local preference caching via `shared_preferences`.
- WCAG AA compliant dual-contrast color palettes for light and dark modes.

---

## 🛠️ Tech Stack & Architecture

| Layer | Technology |
| :--- | :--- |
| **Frontend Framework** | [Flutter](https://flutter.dev) (Web, iOS, Android, Desktop) |
| **State Management** | [Flutter Riverpod 2.6.1](https://riverpod.dev) |
| **Open Banking Provider** | TrueLayer REST & Webhooks API |
| **PDF Extraction** | `pdfx`, `file_picker` |
| **Storage & Auth** | `flutter_secure_storage`, `shared_preferences`, Google Sign-In |
| **Typography & UI** | Google Fonts (Outfit / Inter), Material Design 3 |
| **Deployment** | Vercel Static Web Hosting (`build/web`) |

```
lib/
├── constants/     # Financial rules, categories, and theme tokens
├── core/          # App routing, security wrappers, and theme providers
├── models/        # Budget models, Payslip data structures, TrueLayer schemas
├── screens/       # Dashboard, Salary Audit, TrueLayer Ingestion, Settings
├── services/      # PDF Parser engine, TrueLayer API client, Local storage
└── widgets/       # Interactive trend graphs, popover tooltips, custom cards
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `^3.11.5`
- **Dart SDK**: `^3.11.5`

### Installation & Local Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/fnnktkygl-coderesume/budget_planner_flutter.git
   cd budget_planner_flutter
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run locally on Web**:
   ```bash
   flutter run -d chrome
   ```

4. **Build production web release**:
   ```bash
   flutter build web --release
   ```

---

## 🌐 Live Web Deployment

The application is deployed on Vercel with automated continuous deployment.

- **Primary Web URL**: [https://aurabudgetpro.vercel.app](https://aurabudgetpro.vercel.app)
- **Alternate Alias**: [https://aurabudget-pro.vercel.app](https://aurabudget-pro.vercel.app)

---

## 📜 License & Compliance

Developed with strict data protection compliance (GDPR Art. 6.1.e and financial data isolation).
