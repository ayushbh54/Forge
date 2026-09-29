# 🏗️ Nirmaan OS — Industrial-Grade Project Operating System
> **Smart India Hackathon 2026 | Problem Statement: SIH26122**  
> *Developed for Oil India Limited (OIL) — Duliajan Pipeline & Infrastructure Mega-Projects*

[![Backend Build & Types](https://github.com/ayushbh54/Forge/actions/workflows/backend-ci.yml/badge.svg)](https://github.com/ayushbh54/Forge/actions/workflows/backend-ci.yml)
[![Build & Release Flutter APK](https://github.com/ayushbh54/Forge/actions/workflows/build-apk.yml/badge.svg)](https://github.com/ayushbh54/Forge/actions/workflows/build-apk.yml)
[![Platform](https://img.shields.io/badge/Platform-Flutter_3.27_|_Next.js_15-0284C7.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-Proprietary_OIL-green.svg)]()

---

## ⚡ Quick Links & Deployment

| Resource | Direct Link / Instructions |
| :--- | :--- |
| **Download Android APK** | Go to [GitHub Actions Releases](https://github.com/ayushbh54/Forge/releases) or Artifacts |
| **Backend on Render** | One-Click Deploy via [Render Blueprint](https://render.com) using `render.yaml` |
| **Next.js REST API** | Port `3000` (Local) / Port `10000` (Render) — 29 Live Endpoints |
| **Flutter Mobile/Desktop** | `nirmaan_app` with 40+ industrial-grade screens & 10 Indian languages |

---

## 🌟 Architecture Overview

```
                      ┌──────────────────────────────────────────────┐
                      │             Nirmaan OS Platform              │
                      └──────────────────────┬───────────────────────┘
                                             │
               ┌─────────────────────────────┴─────────────────────────────┐
               ▼                                                           ▼
┌──────────────────────────────┐                           ┌──────────────────────────────┐
│  Flutter Mobile / Desktop   │                           │    Next.js 15 REST Backend   │
│       (nirmaan_app)          │  ◄── HTTP REST & JSON ──► │  (TypeScript + node:sqlite)  │
│                              │                           │                              │
│ • 40+ High-Fidelity Screens  │                           │ • 29 Live Endpoints          │
│ • 10 Indian Languages        │                           │ • High-Concurrency WAL Mode │
│ • Multi-Key Gemini 2.0 AI    │                           │ • Zero-Config Auto-Seeding   │
│ • Offline Sync & Anti-Spoof  │                           │ • Render Production Deploy   │
└──────────────────────────────┘                           └──────────────┬───────────────┘
                                                                          │
                                                                          ▼
                                                           ┌──────────────────────────────┐
                                                           │   Gemini 2.0 Flash AI Brain  │
                                                           │  (Multi-Key Modular Engine)  │
                                                           └──────────────────────────────┘
```

---

## 📱 How to Get the Flutter Android APK

### Option A: Download Automated Build Artifacts from GitHub
1. Go to the **[Actions Tab](https://github.com/ayushbh54/Forge/actions/workflows/build-apk.yml)** of this repository.
2. Click on the latest workflow run: `Build & Release Nirmaan OS Flutter APK`.
3. Scroll down to **Artifacts**:
   - `Nirmaan-OS-Universal-APK`: Universal release APK compatible with all Android devices.
   - `Nirmaan-OS-All-Architecture-APKs`: Architecture-specific APKs (`arm64-v8a`, `armeabi-v7a`, `x86_64`).
4. Download and install directly on your Android phone or tablet.

### Option B: Build APK Locally
```bash
cd nirmaan_app
flutter pub get
flutter build apk --release --no-tree-shake-icons
# Output located at: nirmaan_app/build/app/outputs/flutter-apk/app-release.apk
```

---

## 🚀 Deploying Backend to Render in 1 Click

### Using Render Blueprint (`render.yaml`):
1. Log in to [Render Dashboard](https://dashboard.render.com).
2. Click **New +** $\rightarrow$ **Blueprint**.
3. Connect your GitHub repository: `https://github.com/ayushbh54/Forge`.
4. Render will auto-detect `render.yaml` and configure:
   - **Service Name**: `nirmaan-backend`
   - **Environment**: Node.js 22 (`22.12.0`)
   - **Build Command**: `npm install && npm run build`
   - **Start Command**: `npm run start`
   - **Port**: `10000`
5. *(Optional)* Add your `GEMINI_API_KEY` in Render Environment Variables.
6. Click **Apply** — Your live API will be live in 2 minutes!

---

## 🛠️ Complete Feature Inventory

### 1. FIDIC Contracts & Legal Governance
- **Clause 13 Variation Orders** (`variation_order_screen.dart`): Change register `VO-2026-01` to `VO-2026-06`, 3-stage approval workflow.
- **Clause 20 Dispute Adjudication Board (DAB)** (`dispute_adjudication_screen.dart`): 28-day notice rule, EOT claims, and Cl. 14.8 delayed payment financing calculator.
- **Subclause 8.7 Liquidated Damages** (`liquidated_damages_screen.dart`): Delay penalties, employer vs contractor delay offset.

### 2. Engineering & Quality Assurance
- **Pipeline Weld Joint NDT Radiography** (`pipeline_ndt_screen.dart`): 18" API 5L X70 joints, RT/UT/MPT/VT, 24-hr hydrotest pressure drop chart.
- **Digital Twin 3D / Isometric Site Map** (`digital_twin_site_map_screen.dart`): 2400x2200 GIS canvas, pipeline spreads, LiDAR overlay, asset detail sheets.
- **Concrete Pour Card & Cube QA** (`concrete_pour_qa_screen.dart`): M35/M40 mix design, 7-day & 28-day break tests.
- **Soil Strata & Geotechnical Log** (`soil_strata_log_screen.dart`): Trenching strata, rock blasting permits, OISD-141 depth cover.

### 3. AI & Field Intelligence
- **Gemini 2.0 AI Brain Multi-Key Setup** (`gemini_keys_screen.dart`): Independent API keys for Voice NLP, Tender PDF, Risk Radar, and Copilot.
- **Bhashini Dialect Speech Tuner** (`dialect_speech_tuner_screen.dart`): 5 Indic models (Assamese, Bhojpuri, Hinglish, Hindi, Bengali) + 24-channel acoustic visualizer.
- **Institutional Memory Engine** (`institutional_memory_screen.dart`): 6 historic Oil India pipeline case studies and lessons learned search.
- **Risk Radar Predictor** (`risk_radar_screen.dart`): 2–4 week forward delay predictor and recovery checklists.

### 4. Field Operations & Workforce
- **Anti-Spoof Geofenced Attendance** (`attendance_screen.dart`): <100m Duliajan boundary check, mock location detection, facial liveness proof.
- **Multi-Stakeholder Portal** (`stakeholder_portal_screen.dart`): 4-role switcher (Client OIL Director, EPC L&T, TPIA EIL, Subcontractor Foremen).
- **HSE Digital Permit-to-Work** (`safety_management_screen.dart`): Hot Work, Working at Height, Confined Space, live H2S/LEL sensors.
- **Material QR Scanner & Weighbridge** (`qr_material_scanner_screen.dart` & `weighbridge_ticket_screen.dart`): Mill Test Certificates (MTC) & GRN.
- **Primavera P6 Exporter** (`schedule_export_screen.dart`): Export active schedule into `.XER` / `.XML` / `.MPP`.
- **Executive Progress Dossier** (`executive_report_screen.dart`): Tamper-proof WPR/MPR PDF transmittals.

---

## 🇮🇳 10 Indian Languages Supported
1. English (`en`)
2. हिन्दी - Hindi (`hi`)
3. অসমীয়া - Assamese (`as`)
4. বাংলা - Bengali (`bn`)
5. मराठी - Marathi (`mr`)
6. తెలుగు - Telugu (`te`)
7. தமிழ் - Tamil (`ta`)
8. ಕನ್ನಡ - Kannada (`kn`)
9. മലയാളം - Malayalam (`ml`)
10. ગુજરાતી - Gujarati (`gu`)

---

## 🧑‍💻 Local Development Setup

### 1. Run Backend Server
```bash
npm install
npm run build
npm run dev -- --port 3000
```

### 2. Run Flutter App
```bash
cd nirmaan_app
flutter pub get
flutter run -d macos    # For macOS Desktop
flutter run -d chrome   # For Web
flutter run -d android  # For Android Device/Emulator
```

---

## 📄 License
Proprietary — Developed for Smart India Hackathon 2026 / Oil India Limited.
