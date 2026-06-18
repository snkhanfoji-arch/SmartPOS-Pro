# SmartPOS Pro 🏪

SmartPOS Pro is a pristine, 100% offline-first POS & retail-billing mobile application designed specifically for shopkeepers and small retail operators.

This project is built using **Flutter 3.22.0** (compatible with modern dart SDKs) and utilizes reliable local SQLite database storage to manage products inventory and store sales histories without requiring any active internet connection.

---

## 🚀 Key Features

*   **Products Inventory Manager**: Grid-based inventory tracker supporting dynamic stock validations, creation, price modifications, and inventory tracking.
*   **Billing Terminal**: Fast-touch checkout layout with dynamic quantity incrementors and real-time total updates.
*   **Automatic Inventory Deductions**: Purchasing products automatically deducts inventories in real-time.
*   **Sales Ledger History**: View prior tax invoices, overall gross revenue charts/metrics, and reprint details instantly.
*   **Hi-Fi PDF Receipts**: Configures professional layout outputs automatically optimized for 80mm thermal receipt roll printers using vector canvas generation.
*   **Settings & Backup**: Update store headers, custom currency symbols (e.g. `₨`, `$`), and trigger complete SQLite binary backup dumps.

---

## 🛠️ Tech Stack & Packages

- **Flutter**: `^3.22.0`
- **sqflite**: SQLite driver for reliable offline storage (`^2.3.3`)
- **pdf**: Layout generator for POS receipts (`^3.10.8`)
- **printing**: Share, view, or connect to thermal physical printers directly (`^5.11.1`)
- **intl**: Date-time and currency formatting utilities (`^0.19.3`)
- **path_provider**: Access device-specific directory paths (`^2.1.4`)

---

## 🧱 SQLite Database Schemas

We construct two local tables inside `smartpos_pro.db`:

### 1. `products` Table
```sql
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  price REAL NOT NULL,
  stock INTEGER NOT NULL
);
```

### 2. `bills` Table
```sql
CREATE TABLE bills (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  total REAL NOT NULL,
  items_json TEXT NOT NULL
);
```
*(The `items_json` column serializes a structured JSON list recording exact snapshot descriptions of each bought item to safeguard historical pricing integrity).*

---

## 🏗️ Codemagic Continuous Integration (CI) Build Steps

To build the release-ready **Production APK (`smartpos_pro.apk`)** or **iOS App Store Archive** using **Codemagic**, follow these quick steps:

### 1. Project Integration
1. Log in to [Codemagic](https://codemagic.io/).
2. Connect your Git repository provider (GitHub, GitLab, Bitbucket, or custom git).
3. Select **smartpos_pro** from the application list.

### 2. Configuration Settings
Select **Flutter App** as the project type. In the workflow editor:

#### 🟢 Build Environment
- **Build Platform**: Choose **Android** (or both Android & iOS).
- **Flutter version**: Select `3.22.x` or `channel: stable`.
- **Xcode version**: Use the latest stable version if compiling for iOS.
- **Java version**: `17` (required for modern Gradle tooling).

#### 🟢 Build Triggers
- Set triggers on `Push` or `Pull Request` to branch `main`.

#### 🟢 Environment Variables
Add these key entries (if signing keys are utilized for App Store deployments):
- `FCI_BUILD_ID` (auto-generated)
- Keystore file uploading (via **Environment subgroups** under Android signing configurations if generating production Google Play binaries).

#### 🟢 Build Action Runner
Provide the target configuration paths:
*   **Project Path**: `.` (root directory)
*   **Android Build Action**: `APK` or `App Bundle` (AAB)
*   **Build Mode**: `Release`
*   **Build Arguments**: `--release`

---

### 3. Step-by-Step Custom Compilation Script
If utilizing a `codemagic.yaml` configuration file, drop this exact, build-ready manifest in your project root:

```yaml
# codemagic.yaml config
workflows:
  android-release:
    name: SmartPOS Pro Android Release Build
    max_build_duration: 30
    environment:
      groups:
        - signing # Keystore variables setup (Keystore credentials, etc.)
      flutter: stable
      java: 17
    triggering:
      events:
        - push
      branches:
        - main
    scripts:
      - name: Fetch stable dependencies
        script: |
          flutter pub get
      - name: Analyze formatting and lints
        script: |
          flutter analyze
      - name: Build Android APK (Release)
        script: |
          flutter build apk --release --build-number=$BUILD_NUMBER
    artifacts:
      - build/app/outputs/flutter-apk/*.apk
    publishing:
      email:
        recipients:
          - zerlinkhan65@gmail.com # Dispatches successful builds instantly
        notify:
          success: true
          failure: true
```

---

## 📲 Local Manual Run

To build and run the app manually on an Android/iOS emulator or connected physical device:
```bash
# 1. Fetch dependencies
flutter pub get

# 2. Verify connected devices
flutter devices

# 3. Compile and boot application in debug mode
flutter run
```

*Crafted with absolute dedication for immediate, zero-lag shopkeeper operations.*
