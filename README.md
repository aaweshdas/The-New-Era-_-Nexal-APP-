<p align="center">
  <img src="assets/nexal_logo.png" width="140" alt="Nexal Logo" />
</p>

<h1 align="center">N E X A L</h1>

<p align="center">
  <strong>The Next-Gen Unified Super App Experience</strong><br/>
  <sub>A ultra-performant, single-install ecosystem combining Social Feeds, Voice AI, Self-Hosted Navigation, 3D Gaming, Real-Time Messaging, and Smart Vision.</sub>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white" /></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.10+-0175C2?style=for-the-badge&logo=dart&logoColor=white" /></a>
  <a href="https://nodejs.org"><img src="https://img.shields.io/badge/Node.js-20+-339933?style=for-the-badge&logo=node.js&logoColor=white" /></a>
  <a href="https://www.typescriptlang.org"><img src="https://img.shields.io/badge/TypeScript-5.4+-3178C6?style=for-the-badge&logo=typescript&logoColor=white" /></a>
  <a href="https://supabase.com"><img src="https://img.shields.io/badge/Supabase-Supported-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" /></a>
  <a href="https://groq.com"><img src="https://img.shields.io/badge/AI-Groq%20%2B%20Deepgram-F04438?style=for-the-badge" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-EC4899?style=for-the-badge" /></a>
</p>

---

## 📌 Overview

**Nexal** is a Flutter-based super app that seamlessly converges six full-fledged digital platforms into a unified, high-performance client application backed by an isolated, multi-port Node.js microservices gateway:

- **🌌 Quantum Feed & Reels ("Feels")**: Social timeline, short video reels with double-tap reactions, story viewer, comments, and interactive bookmarks.
- **🎙️ ARIA Voice AI Assistant**: Zero-latency voice-to-voice conversational agent built on WebSocket streams, Deepgram STT/TTS, and Groq LLM.
- **🗺️ Self-Hosted Navigation**: Privacy-first MapLibre GL vector maps with turn-by-turn routing using self-hosted Nominatim & OSRM backends.
- **🎮 3D Open-World Gaming**: Embedded WebGL game client and Luanti engine rendered through low-overhead Flutter WebViews.
- **💬 Real-time Cyber Messaging**: Socket.IO direct and group messaging with voice bubbles, media attachments, and thread replies.
- **📷 Smart Vision & Immersive Gallery**: Real-time camera preview powered by Google ML Kit Face Detection, live color filters, 360° Dome View, and River of Time timeline galleries.

---

## 🚀 Key Modules & Feature Highlights

| Module | Features & Capabilities | Tech Stack |
|---|---|---|
| **Social & Reels** | Infinite scroll timeline, short video reels ("Feels"), story viewer, animated reactions, and bookmarking | `provider`, `video_player`, `cached_network_image` |
| **ARIA AI Voice** | Real-time streaming voice-to-voice conversation engine with low-latency audio processing | Deepgram STT/TTS, Groq LLM, WebSockets, `record`, `audioplayers` |
| **Navigation & Maps** | 3D tile rendering, turn-by-turn routing, pre-warmed video loader, and geocoding | MapLibre GL, Nominatim, OSRM, `geolocator`, `geocoding` |
| **3D Open World** | WebGL 3D game client integration & Luanti engine | `webview_flutter`, Node.js static game server |
| **Messaging & Chat** | Direct & group chats, voice bubbles, image attachments, and unread counters | `socket_io_client`, Express, `emoji_picker_flutter` |
| **Smart Vision Camera** | Live camera preview, color filters, Google ML Kit face detection overlay, gesture zoom | `camera`, `google_mlkit_face_detection` |
| **Immersive Gallery** | 360° Dome View, River of Time, monthly timeline, and high-definition photo viewer | `sensors_plus`, `gal`, `share_plus` |
| **Auth & Security** | Supabase OAuth (Google, Facebook), Email/Password, TOTP 2FA, and guest exploration | `supabase_flutter`, `google_sign_in`, `qr_flutter` |
| **Design Engine** | Obsidian glassmorphism, Particle Backgrounds, Gyro Parallax, and Quantum Arc Menu | `glassmorphism_ui`, `flutter_animate`, `lucide_icons_flutter` |

---

## ⚡ Performance & Optimization Engine

Nexal is engineered for **buttery smooth 60 FPS performance** through comprehensive rendering and memory optimizations:

- **Isolated Layer Repaints**: Critical components (`PostCard`, `VideoPlayer`, `ParticleBackground`) are wrapped in `RepaintBoundary` wrappers to prevent cascading tree redraws.
- **Smart Background Deduplication**: Prevents duplicate video decoder instances when switching between galaxy menu and sub-screens.
- **Painter & Layout Caching**: Static `TextPainter` reuse in `_CelestialTextPainter` eliminates over 180 layout recalculations/sec.
- **Image & Asset Pre-warming**: Critical background wallpapers and nav icons are precached during splash boot up; memory cache limits (`memCacheWidth: 600`) ensure low RAM footprint.
- **Asynchronous I/O Optimization**: `SharedPreferences` instances and `ThemeData` tokens are cached in memory to eliminate async I/O stutter on UI events.

---

## 🏗️ System Architecture

```
                                ┌────────────────────────┐
                                │     Flutter Client     │
                                └───────────┬────────────┘
                                            │
                                            ▼
                                ┌────────────────────────┐
                                │   Gateway Microservice │  (Port 10000)
                                └───────────┬────────────┘
                                            │
       ┌────────────────┬───────────────────┼───────────────────┬────────────────┬────────────────┐
       │                │                   │                   │                │                │
       ▼                ▼                   ▼                   ▼                ▼                ▼
 ┌───────────┐    ┌───────────┐       ┌───────────┐       ┌───────────┐    ┌───────────┐    ┌───────────┐
 │   ARIA    │    │  Search   │       │   Map     │       │   Game    │    │  Camera   │    │ Settings  │
 │ AI Engine │    │REST Backend│       │  Engine   │       │  Server   │    │  Backend  │    │  Backend  │
 │(Port 3003)│    │(Port 3004)│       │(Port 3006)│       │(Port 3005)│    │(Port 3007)│    │(Port 3008)│
 └─────┬─────┘    └─────┬─────┘       └─────┬─────┘       └───────────┘    └───────────┘    └───────────┘
       │                │                   │
       ▼                ▼                   ▼
┌──────────────┐ ┌──────────────┐   ┌──────────────┐
│ Groq LLM &   │ │ Supabase Auth│   │ Nominatim /  │
│ Deepgram Voice│ │  & Database  │   │  OSRM Maps   │
└──────────────┘ └──────────────┘   └──────────────┘
```

---

## 📂 Project Structure

```text
Nexal_App/
├── lib/
│   ├── main.dart                  # App entry point, MultiProvider & global error boundary
│   ├── config/                    # Global app configuration & API gateway endpoints
│   ├── models/                    # Typed data models (User, Post, Session)
│   ├── providers/                 # State management (Auth, Feed, User, Notifications, Background)
│   ├── services/                  # Network REST, Socket.IO, Supabase & ARIA client services
│   ├── theme/                     # App Theme, cached text styles, and color tokens
│   ├── screens/                   # Core application views
│   │   ├── auth/                  # Splash router, Login & OAuth flows
│   │   ├── home_screen.dart       # Galaxy mode & Quantum Arc menu home screen
│   │   ├── home_view.dart         # Main social timeline feed
│   │   ├── feels_view.dart        # Short video reels player
│   │   ├── ai_assist_view.dart    # ARIA AI voice assistant screen
│   │   ├── map_view.dart          # Vector map & turn-by-turn navigation view
│   │   ├── camera_view.dart       # Smart camera & ML Kit face detection
│   │   ├── gallery_view.dart      # 360° Dome & River of Time gallery
│   │   ├── messages_view.dart     # Direct & group messaging hub
│   │   └── open_world_games_view.dart # WebGL 3D game screen
│   └── widgets/                   # Reusable UI components (Quantum Arc Menu, Post Cards, Backgrounds)
│
├── Backend/
│   ├── src/gateway.ts             # Gateway reverse proxy router (Port 10000)
│   ├── aria_backend/              # ARIA AI voice WebSocket server (Port 3003)
│   ├── search_backend/            # Search & feed REST service (Port 3004)
│   ├── game_backend/              # WebGL static game server (Port 3005)
│   ├── Map_Backend/               # OpenStreetMap tile proxy, Nominatim & OSRM (Port 3006)
│   ├── camera_backend/            # Camera uploads & storage server (Port 3007)
│   └── Setting Backend/           # User preferences sync service (Port 3008)
│
├── android/                       # Android native configuration
├── ios/                           # iOS native configuration
└── assets/                        # Background wallpapers, nav icons, map tiles, and game assets
```

---

## 🛠️ Getting Started

### Prerequisites

- **Flutter SDK**: `>=3.10.7`
- **Node.js**: `>=20.x` & `npm >=10.x`
- **Target Device**: Physical Android or iOS device recommended for Camera, GPS, Gyroscope, and Microphone features.

---

### 1. Mobile App Setup

```bash
# Clone the repository
git clone https://github.com/aaweshdas/The-New-Era-_-Nexal-APP-.git
cd The-New-Era-_-Nexal-APP-

# Install Flutter dependencies
flutter pub get

# Run on connected device
flutter run
```

---

### 2. Microservices Backend Setup

```bash
# Navigate to the backend directory
cd Backend

# Install Node.js dependencies
npm install

# Copy environment configuration for ARIA AI backend
cp aria_backend/.env.example aria_backend/.env

# Start all microservices via unified Gateway
npm run dev
```

---

## 🔐 Environment Configuration

Create `Backend/aria_backend/.env`:

```env
# ARIA AI Service Credentials
GROQ_API_KEY=your_groq_api_key
DEEPGRAM_API_KEY=your_deepgram_api_key
PORT=3003
```

> [!TIP]
> - **Groq API Key**: Obtain for free at [console.groq.com](https://console.groq.com)
> - **Deepgram API Key**: Obtain for free at [console.deepgram.com](https://console.deepgram.com)

---

## 🌐 Platform Matrix

| Platform | Support | Functional Highlights |
|:---:|:---:|---|
| **Android** | ✅ Supported | Complete feature parity (Camera, ML Kit, Sensors, Maps, Microservices) |
| **iOS** | ✅ Supported | Complete feature parity (requires iOS camera/microphone permissions in `Info.plist`) |
| **Web** | ⚠️ Partial | WebGL 3D Games & Vector Maps work seamlessly; microphone requires HTTPS context |
| **Desktop** | ⚠️ Partial | Navigation, Messaging & REST services supported; hardware camera capabilities limited |

---

## 🧰 Tech Stack

- **Frontend**: Flutter, Dart, Material 3, Glassmorphism UI
- **State Management**: Provider
- **Backend Gateway**: Node.js, TypeScript, Express, Socket.IO, `http-proxy`
- **AI & Speech**: Groq LLM API, Deepgram STT & TTS, WebSockets
- **Maps & Location**: MapLibre GL, Nominatim (Geocoding), OSRM (Routing)
- **Vision & ML**: Flutter `camera`, Google ML Kit Face Detection
- **Database & Auth**: Supabase Flutter, Google Sign-In, TOTP 2FA

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.

---

## 👤 Author

**Aawesh Das**
- GitHub: [@aaweshdas](https://github.com/aaweshdas)

---

<p align="center">
  <sub>Built with ❤️ using Flutter & Node.js</sub>
</p>
