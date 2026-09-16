# About SupaMobile

> **Supabase in your pocket** — Complete mobile control over your Supabase projects, databases, users, logs, edge functions, and real-time infrastructure anytime, anywhere.

---

## 🎯 App Motto & Core Purpose

### Motto
*"Empowering developers to monitor, manage, and query their entire Supabase infrastructure on the go."*

### Core Purpose
**SupaMobile** is a full-featured, cross-platform mobile administration dashboard built for Supabase developers, database administrators, and cloud engineers. It solves the critical gap of managing Supabase backend services on mobile devices without relying on desktop web browsers. By connecting securely via a **Supabase Personal Access Token (PAT)**, users gain immediate access to multi-project management, database querying, RLS policy inspection, storage buckets, Edge Functions logs, real-time channels, host metrics, and user authentication management—all optimized for mobile touch screens with a modern dark UI aesthetic.

---

## 🏗️ Architecture & Project Structure

SupaMobile follows **Clean Architecture** principles combined with a **Feature-First** directory structure.

```
supamobile/
├── android/                 # Android native project configuration & build files
├── ios/                     # iOS native project configuration & Xcode workspace
├── assets/                  # App assets (logo, branding, icons, env files)
├── lib/
│   ├── main.dart            # App entry point (initializes .env, Riverpod ProviderScope)
│   ├── app.dart             # Main MaterialApp, GoRouter setup, theme binding, auth routing
│   │
│   ├── core/                # Core system abstractions & global services
│   │   ├── api/             # API client layer for Supabase Management API & Analytics API
│   │   │   ├── management_api.dart        # Supabase Management API calls (projects, keys, metrics, functions)
│   │   │   ├── management_api_client.dart # HTTP wrapper handling PAT authorization & error handling
│   │   │   ├── analytics_api.dart         # Analytics & telemetry endpoints interface
│   │   │   ├── project_api.dart           # Project-level endpoint wrappers
│   │   │   └── time_helpers.dart          # Date/time parsing for API telemetry
│   │   ├── config/          # Global application configuration constants
│   │   ├── models/          # Core domain data models (Project, ApiUsagePoint)
│   │   ├── providers/       # Global Riverpod state providers (PAT, active project, keys, theme, security)
│   │   ├── services/        # Service integrations (RevenueCat, Security, Subscriptions, Anon identity)
│   │   ├── storage/         # Secure Encrypted Hardware Storage (FlutterSecureStorage)
│   │   ├── theme/           # Design System, custom dark/light themes, color tokens & glassmorphism
│   │   └── utils/           # Utilities, string formatters & metrics parsers
│   │
│   ├── features/            # Modular feature domains
│   │   ├── auth/            # Personal Access Token authentication & key prompts
│   │   ├── projects/        # Multi-project selector, project cards & setting screens
│   │   ├── dashboard/       # Project health metrics, interactive API usage charts & counts
│   │   ├── tables/          # Database schema inspector, table data viewer & row details
│   │   ├── sql/             # Mobile SQL Editor with query runner & snippet storage
│   │   ├── auth_users/      # Authentication user directory, auth providers, RLS policies & stats
│   │   ├── storage/         # Storage buckets browser, file uploader & object management
│   │   ├── functions/       # Supabase Edge Functions monitor, secrets manager & invocation logs
│   │   ├── logs/            # Real-time server log streamer & Audit log inspector
│   │   ├── realtime/        # Realtime WebSocket console monitor & event inspector
│   │   ├── database/        # Database functions, triggers, indexes & publication manager
│   │   ├── infrastructure/  # Prometheus host metrics, CPU/Memory/Disk telemetry
│   │   ├── subscription/    # RevenueCat Pro subscription paywall & pricing tiers
│   │   ├── profile/         # User profile settings, biometric lock toggles & security options
│   │   └── feedback/        # In-app feedback submission tool
│   │
│   └── widgets/             # Reusable UI component library (cards, inputs, nav, buttons, drawers)
│
├── pubspec.yaml             # Project dependencies and asset definitions
└── README.md                # Project overview
```

---

## 🛠️ Technology Stack & Package Purpose

| Technology / Package | Category | Purpose & Description |
| :--- | :--- | :--- |
| **Flutter / Dart SDK (^3.11.1)** | Core Framework | Cross-platform SDK enabling native iOS, Android, Desktop, and Web performance from a single Dart codebase. |
| **`flutter_riverpod` (^3.3.1)** | State Management | Declarative, compile-safe state management & dependency injection framework used across all screens and services. |
| **`riverpod_annotation` (^4.0.2)** | Code Generation | Annotation-driven Riverpod provider generation for clean state definitions. |
| **`go_router` (^17.1.0)** | Navigation & Routing | Declarative routing system featuring nested `ShellRoute` navigation, URL parameters, and auth redirection guards. |
| **`supabase_flutter` (^2.12.2)** | Backend Client | Official Supabase SDK for interacting directly with Supabase Postgres, Realtime channels, Storage buckets, and Auth. |
| **`http` (^1.6.0)** | Networking | HTTP client used to interact with the **Supabase Management REST API** (`api.supabase.com`). |
| **`flutter_secure_storage` (^10.0.0)** | Security & Storage | Hardware-backed encrypted storage (Keychain/Keystore) to safely persist sensitive Personal Access Tokens (PAT), Anon Keys, and Service Role Keys. |
| **`local_auth` (^3.0.1)** | Biometric Auth | Device biometric authentication (Face ID / Fingerprint / Touch ID) protecting the app via `AppLockWrapper`. |
| **`fl_chart` (^1.2.0)** | Data Visualization | Interactive chart library for displaying real-time API request volumes, error spikes, CPU usage, and auth statistics. |
| **`purchases_flutter` (^10.3.0)** | Monetization | RevenueCat SDK integration for managing Pro subscriptions, paywalls, and in-app purchases (`purchases_ui_flutter`). |
| **`firebase_core` & `cloud_firestore`** | Analytics / Sync | Firebase platform integration for user feedback sync, remote diagnostics, and cloud fallback storage. |
| **`google_fonts` (^8.0.2)** | Typography | Modern custom typography for clean UI readability. |
| **`cached_network_image` (^3.4.1)** | Asset Management | High-performance image caching for previewing bucket media and user avatars. |
| **`flutter_svg` (^2.2.4)** | Graphic Assets | SVG rendering library for crisp vector iconography across resolutions. |
| **`shimmer` (^3.0.0)** | UI Experience | Polished shimmer skeleton loading indicators during data fetching. |
| **`intl` (^0.20.2) & `timeago` (^3.7.1)** | Formatting | Date/time localization, metric formatting, and human-readable time interval formatting (e.g., "5 mins ago"). |
| **`flutter_dotenv` (^6.0.0)** | Environment Config | Secure parsing and loading of environment configuration variables from `.env`. |
| **`url_launcher` & `flutter_web_auth_2`** | Web & OAuth | Opening external links (Supabase dashboard, documentation) and handling browser OAuth redirect flows. |

---

## 🚀 Key Feature Modules

1. **Multi-Project Management**: Effortlessly switch between Supabase projects linked to your account with automatic API key detection (`anon` & `service_role`).
2. **Interactive Dashboard**: Track total API requests, response status breakdown (2xx, 4xx, 5xx), and database health with dynamic line charts.
3. **Database & Schema Browser**: View database tables, inspect table schemas, browse row records, and navigate relational data structures.
4. **Mobile SQL Editor**: Write, execute, and format custom SQL queries on the fly, with snippet saving capabilities directly stored on encrypted device storage.
5. **Auth & User Administration**: Monitor registered users, inspect Row Level Security (RLS) policies, view active authentication providers, and check auth user metrics.
6. **Edge Functions & Secrets**: Monitor deployed Supabase Edge Functions, view function status/invocations, and manage environment secrets.
7. **Storage Buckets Manager**: Browse storage buckets, inspect stored files/objects, and view metadata.
8. **Real-time Logs & Audit Trail**: Stream API logs, database logs, and system audit trails in real time.
9. **Infrastructure & Prometheus Host Metrics**: Inspect server health, CPU consumption, memory usage, and database connection metrics.
10. **Security & App Lock**: Lock app access behind mandatory Face ID / Fingerprint authentication or passcode protection.
