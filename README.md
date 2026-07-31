<p align="center">
  <img src="assets/nexal_logo.png" width="140" alt="Nexal Logo" />
</p>

<h1 align="center">N E X A L</h1>

<p align="center">
  <strong>The Next-Gen Unified Super App Experience</strong><br/>
  <sub>An ultra-performant, single-install ecosystem combining Social Feeds, ARIA Voice AI, Self-Hosted Navigation, 3D Gaming, Real-Time Cyber Messaging, and Smart Vision.</sub>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.22+-02569B?style=for-the-badge&logo=flutter&logoColor=white" /></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.4+-0175C2?style=for-the-badge&logo=dart&logoColor=white" /></a>
  <a href="https://supabase.com"><img src="https://img.shields.io/badge/Supabase-Supported-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" /></a>
  <a href="https://groq.com"><img src="https://img.shields.io/badge/AI-Groq%20%2B%20Deepgram-F04438?style=for-the-badge" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-EC4899?style=for-the-badge" /></a>
</p>

---

## 📌 Overview

**Nexal** is a Flutter-powered next-generation super app that seamlessly converges six full-fledged digital platforms into a unified, high-performance client application:

- **🌌 Quantum Social Feed & Feels**: Interactive social timeline, video reels ("Feels"), story viewers, double-tap reactions, and bookmarks.
- **🎙️ ARIA Voice AI Assistant**: Zero-latency voice-to-voice conversational AI powered by Deepgram STT/TTS, Groq LLM, and WebSockets.
- **🗺️ Self-Hosted Map & Navigation**: Vector maps with MapLibre GL, turn-by-turn routing, Nominatim geocoding, and location bookmarking.
- **🎮 3D Open-World Gaming**: Embedded WebGL game client engine (Voxel Realm & World) rendered via low-overhead WebViews.
- **💬 Cyber Messaging Hub**: Direct & group chat hub with voice notes, image/video sharing, unread indicators, and live typing status.
- **📷 Smart Vision & Immersive Gallery**: Live camera preview with Google ML Kit Face Detection, live filters, 360° Dome View, and River of Time timeline gallery.
- **🔐 Next-Gen Authentication**: Supabase OAuth (Google, Facebook), Email/Password, TOTP 2FA, and Guest Mode, framed in an Obsidian Glassmorphic container.

---

## 🚀 Key Modules & Capabilities

| Module | Core Features & Capabilities | Tech Stack / Packages |
|---|---|---|
| **Social Timeline** | Timeline feed, post creation with media uploads, likes, bookmarking, profile analytics, and search | `provider`, `cached_network_image`, `flutter_animate` |
| **Feels (Video Reels)** | Vertical video reels, auto-play queue, double-tap heart animations, and audio player | `video_player`, `audioplayers` |
| **ARIA AI Voice** | Full voice-to-voice AI assistant with visual waveform orb and real-time streaming | Deepgram STT/TTS, Groq LLM, WebSockets, `record` |
| **Map & Navigation** | Vector maps, custom tile styles, turn-by-turn OSRM routing, Nominatim search, and GPS tracking | MapLibre GL, `geolocator`, `geocoding` |
| **3D Gaming Hub** | WebGL 3D Voxel Realm & World game engine with interactive touch controls | `webview_flutter`, `flutter_inappwebview` |
| **Cyber Messaging** | Direct & group messaging, voice bubbles, image attachments, call screens, and group management | `socket_io_client`, Supabase Realtime |
| **Smart Vision Camera** | Live camera preview, color filters, Google ML Kit face detection overlay, snap capture | `camera`, `google_mlkit_face_detection` |
| **Immersive Gallery** | 360° Gyroscope Dome View, River of Time 3D wall, Monthly Timeline, and HD viewer | `sensors_plus`, `gal`, `share_plus` |
| **Auth & Security** | Obsidian Glassmorphic Auth Box, Supabase Auth, Google/FB OAuth, TOTP 2FA, and Guest Mode | `supabase_flutter`, `google_sign_in`, `qr_flutter` |

---

## 🎨 Design System & Aesthetics

Nexal features a **state-of-the-art Obsidian Glassmorphic Design System**:

- **Curated Wallpaper Engine**: Organized background asset management divided into `active_screens` and `preset_wallpapers`.
- **Dynamic Background Swapper**: Real-time wallpaper picker allowing users to switch background styles live across the app.
- **Obsidian Glass Cards**: High-density backdrop blurs (`sigma: 30`), translucent dark tint (`0xFF070A14`), specular beam highlights, and 3D squircle logo badges.
- **Micro-Animations**: Fluid entrance transitions, bouncy squircle badges, and glowing multi-color shimmer typography using `flutter_animate` and Google Fonts (`Outfit`, `Rye`, `Cinzel`).

---

## 📂 Project Structure

```text
Nexal_App/
├── assets/                        # Organized Static Assets & Wallpapers
│   ├── backgrounds/               # Managed Background Engine
│   │   ├── active_screens/        # Active wallpaper images assigned per screen
│   │   └── preset_wallpapers/     # User-selectable theme background wallpapers
│   ├── gallery/                   # Sample images & 360° dome panoramas
│   ├── images/                    # UI branding banners & avatars
│   ├── map/                       # Offline map styles & vector icons
│   ├── nav_icons/                 # Custom navigation bar icon assets
│   ├── videos/                    # Sample Feels video clips
│   ├── voxel_realm/               # WebGL 3D game assets
│   ├── nexal_logo.png             # Official Nexal 3D Emblem Logo
│   └── 3d_map.png                 # Map preview asset
│
├── lib/                           # Flutter Application Codebase
│   ├── main.dart                  # Application Entrypoint & MultiProvider setup
│   ├── config/                    # Global App Configuration & Endpoints
│   ├── controllers/               # Custom UI Controllers
│   ├── models/                    # Data Models (User, Post, Chat, Story, Notification)
│   ├── providers/                 # State Management Providers (Auth, Feed, Theme, User)
│   ├── screens/                   # Core Application Screens & Views
│   │   ├── auth/                  # LoginScreen, SplashScreen, 2FA Verification
│   │   ├── settings/              # Settings modal, Wallpaper Picker, Account Settings
│   │   ├── home_screen.dart       # Main Container with Galaxy Navigation Bar
│   │   ├── home_view.dart         # Social Timeline Feed View
│   │   ├── feels_view.dart        # Short Video Reels ("Feels") View
│   │   ├── ai_assist_view.dart    # ARIA AI Voice Assistant View
│   │   ├── map_view.dart          # Vector Map & Turn-by-Turn Routing View
│   │   ├── camera_view.dart       # Smart Vision & ML Kit Face Detection View
│   │   ├── camera_preview_screen.dart # Camera Post-Capture Preview
│   │   ├── gallery_view.dart      # Standard Gallery Grid
│   │   ├── immersive_dome_gallery_view.dart # 360° Gyroscope Dome View
│   │   ├── monthly_timeline_view.dart # River of Time & Monthly Timeline
│   │   ├── messages_view.dart     # Cyber Messaging Hub
│   │   ├── chat_screen.dart       # Direct & Group Chat Screen
│   │   ├── call_screen.dart       # Audio/Video Call Screen
│   │   ├── open_world_games_view.dart # 3D WebGL Games Hub
│   │   ├── game_webview_screen.dart # WebGL Game Viewport Screen
│   │   ├── profile_view.dart      # User Profile Screen
│   │   └── search_view.dart       # Global Search View
│   ├── services/                  # Network REST, WebSockets, Supabase & ML Services
│   ├── theme/                     # App Theme, Color Tokens & Typography
│   ├── utils/                     # Helper Utilities & Formatters
│   └── widgets/                   # Modular UI Components & Cards
│
├── android/                       # Native Android Project Files
├── ios/                           # Native iOS Project Files
├── pubspec.yaml                   # Package Dependencies & Asset Manifest
└── analysis_options.yaml          # Static Analysis & Linter Rules
```

---

## ⚡ Performance & Optimization Architecture

Engineered for **fluid 60 FPS performance**:

- **Repaint Boundaries**: High-activity components (`PostCard`, `VideoPlayerWidget`, `ParticleBackground`) are wrapped in `RepaintBoundary` nodes to isolate paint invalidations.
- **Background Asset Deduplication**: Dedicated active screen wallpaper paths isolate image loading per view.
- **Lazy Loading & Pre-caching**: Critical UI wallpapers and icons are precached during splash boot.
- **MemCache Constraints**: All network and local images utilize `memCacheWidth` bounds to reduce GPU memory footprint.

---

## 🛠️ Getting Started

### Prerequisites

- **Flutter SDK**: `>=3.22.0`
- **Dart SDK**: `>=3.4.0`
- **Physical Device**: Physical Android or iOS device recommended for Camera, ML Kit, Gyroscope, GPS, and Audio recording.

---

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/aaweshdas/The-New-Era-_-Nexal-APP-.git
   cd The-New-Era-_-Nexal-APP-
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify Static Analysis**:
   ```bash
   dart analyze lib/
   ```

4. **Launch the application**:
   ```bash
   flutter run
   ```

---

## 🌐 Platform Matrix

| Platform | Support | Notes |
|:---:|:---:|---|
| **Android** | ✅ Supported | Complete feature parity (Camera, ML Kit, Gyroscope, GPS, WebGL) |
| **iOS** | ✅ Supported | Full support (requires Camera & Microphone permissions in `Info.plist`) |
| **Web** | ⚠️ Experimental | WebGL 3D Games & Maps supported; Microphone requires HTTPS context |
| **Desktop** | ⚠️ Experimental | Messaging & Navigation functional; hardware camera features limited |

---

## 🧰 Technology Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart 3)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **UI & Animations**: Glassmorphism UI, [Flutter Animate](https://pub.dev/packages/flutter_animate), Lucide Icons, Google Fonts (`Outfit`, `Rye`, `Cinzel`)
- **Backend & Auth**: [Supabase Flutter](https://pub.dev/packages/supabase_flutter), Google Sign-In
- **AI & Speech**: Groq LLM API, Deepgram STT/TTS, WebSockets
- **Maps**: MapLibre GL, Nominatim, OSRM
- **Computer Vision**: Flutter `camera`, Google ML Kit Face Detection
- **Sensors**: `sensors_plus` (Gyroscope, Accelerometer)

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for details.

---

## 👤 Author

**Aawesh Das**
- GitHub: [@aaweshdas](https://github.com/aaweshdas)

<p align="center">
  <sub>Built with ❤️ using Flutter & Dart</sub>
</p>
