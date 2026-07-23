<p align="center">
  <img src="assets/nexal_logo.png" width="140" alt="Nexal Logo" />
</p>

<h1 align="center">NEXAL — Super App Studio</h1>

<p align="center">
  <em>A flagship, next-generation AI Super App engine — built with Flutter, Node.js, WebGL 3D, and a self-hosted OpenStreetMap engine. Consolidation at scale to eliminate storage exhaustion and device fragmentation.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.10+-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Node.js-20+-339933?style=for-the-badge&logo=node.js&logoColor=white" />
  <img src="https://img.shields.io/badge/TypeScript-5.4+-3178C6?style=for-the-badge&logo=typescript&logoColor=white" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-black?style=for-the-badge" />
  <img src="https://img.shields.io/badge/AI-Groq%20%7C%20Deepgram-A855F7?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Maps-OpenStreetMap%20(Self--Hosted)-4CAF50?style=for-the-badge" />
  <img src="https://img.shields.io/badge/License-MIT-EC4899?style=for-the-badge" />
</p>

---

## 📖 Table of Contents

- [✦ The Core Problem: App Fatigue & Storage Exhaustion](#-the-core-problem-app-fatigue--storage-exhaustion)
- [💡 The Nexal Solution: One App, Infinite Cosmos](#-the-nexal-solution-one-app-infinite-cosmos)
- [🏗️ System Architecture](#️-system-architecture)
- [🎨 Design Language & Aesthetic System](#-design-language--aesthetic-system)
- [🚀 Comprehensive Features & Screens](#-comprehensive-features--screens)
  - [✨ Content Creation Studio & Floating FAB](#-content-creation-studio--floating-fab)
  - [🤖 ARIA AI Voice & Vision Companion](#-aria-ai-voice--vision-companion)
  - [🗺️ Self-Hosted Map Engine](#-self-hosted-map-engine)
  - [🎮 3D WebGL Open World Game](#-3d-webgl-open-world-game)
  - [📱 Quantum Social Feed & Feels](#-quantum-social-feed--feels)
  - [💬 WebSocket Real-Time Chat Engine](#-websocket-real-time-chat-engine)
  - [📸 Camera & Live Filters](#-camera--live-filters)
  - [🖼️ Immersive Dome & Timeline Gallery](#-immersive-dome--timeline-gallery)
- [📡 Unified Backend Services & Gateway](#-unified-backend-services--gateway)
- [📂 Project Directory Structure](#-project-directory-structure)
- [⚡ Quick Start & Setup Guide](#-quick-start--setup-guide)
- [🔑 Environment Variables & API Keys](#-environment-variables--api-keys)
- [📦 Technical Dependencies](#-technical-dependencies)
- [📱 Platform Matrix & Requirements](#-platform-matrix--requirements)
- [👤 Author & Credits](#-author--credits)

---

## ✦ The Core Problem: App Fatigue & Storage Exhaustion

Modern smart device ecosystems suffer from **Storage Bloat** and **App Fatigue**. 
* **The Storage Crisis:** The average user maintains dozens of single-purpose apps. A typical map app (350MB+), an AI assistant (200MB+), a 3D explorer game (500MB+), instant messengers (250MB+), and multiple social platforms (400MB+ each) collectively consume **several gigabytes** of local device storage, cache footprints, and RAM overhead.
* **Resource Exhaustion:** Multiple independent applications run overlapping background daemons, sync pipelines, push receivers, and tracking engines, leading to thermal throttling and rapid battery drain.
* **Context Fragmentation:** Navigating between isolated user interfaces with disparate design paradigms interrupts flow, decreases productivity, and complicates user experiences.

---

## 💡 The Nexal Solution: One App, Infinite Cosmos

**Nexal** redefines the mobile paradigm by consolidating five distinct technology layers into a single, high-performance, lightweight **Super App**. By combining social feeds, real-time voice AI, self-hosted navigation, offline gallery tools, and an embedded 3D environment, Nexal eliminates the need for separate installs—**saving up to 80% of device storage space**.

### Why Consolidate under Nexal?
- **Zero Third-Party Map Dependencies**: Built using a 100% self-hosted OpenStreetMap stack (MapLibre GL + Nominatim + OSRM) with native Flutter high-accuracy GPS injection.
- **Real-Time Voice AI (ARIA)**: Low-latency streaming speech-to-text (Deepgram Nova-2), LLM completion streaming (Groq Llama-3.1), and neural text-to-speech (Deepgram Aura-2).
- **Interactive Creation Studio**: Individual, custom-designed modals for Posts, Stories, Video Reels, and Live Streams with background artwork integration (`assets/normal_bg.png`).
- **Unified Microservice Gateway**: 4 independent Node.js backends routed seamlessly behind a single public port (`10000`).

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Flutter Mobile Client                          │
│                                                                         │
│  ┌───────────────────────┐ ┌───────────────────┐ ┌────────────────────┐ │
│  │     19+ Screens       │ │   Design Tokens   │ │   AriaService      │ │
│  │ (Home, Feed, Camera,  │ │ (Glass, Dark Mode,│ │ (Socket.IO Stream, │ │
│  │  ARIA, Gallery, etc.) │ │  Custom Fonts)    │ │  SharedPrefs Store)│ │
│  └───────────────────────┘ └───────────────────┘ └─────────┬──────────┘ │
│                                                            │            │
│  ┌────────────────────────────────────────────────────┐    │ Socket.IO  │
│  │           Native Embedded WebViews                 │    │ + HTTP     │
│  │   MapLibre GL Navigation  │  WebGL 3D Engine       │    │            │
│  └────────────────────────────────────────────────────┘    │            │
└────────────────────────────────────────────────────────────┼────────────┘
                                                             │
┌────────────────────────────────────────────────────────────┼────────────┐
│                    Unified Backend Gateway                 │            │
│                 (Node.js / Express Gateway Port 10000)      │            │
│                                                            │            │
│    /map/*        /api/*             /game/*          /*    │            │
│      ▼             ▼                  ▼               ▼    │            │
│  ┌──────────┐ ┌──────────────┐ ┌────────────┐ ┌──────────┐ │            │
│  │Map Engine│ │Search Server │ │WebGL Game  │ │  ARIA    │ │            │
│  │ Nominatim│ │ REST API     │ │File Server │ │  Engine  │ │            │
│  │ + OSRM   │ │ Search Data  │ │ 3D World   │ │ Groq/Deep│ │            │
│  │ Port 3006│ │ Port 3004    │ │ Port 3005  │ │ Port 3003│ │            │
│  └──────────┘ └──────────────┘ └────────────┘ └──────────┘ │            │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🎨 Design Language & Aesthetic System

Nexal implements a unified **Deep Space Dark Theme** across all components to deliver a flagship experience:

| Token | Hex / Value | Usage |
|---|---|---|
| **Background Dark** | `#070412` | Main screen backdrops & modal overlays |
| **Surface Elev** | `#0F0821` | Glassmorphic cards & container fills |
| **Purple Accent** | `#B07CFF` | Primary action buttons, badges & active glows |
| **Cyan Accent** | `#67E8F9` | Story studio accents, online badges & status indicators |
| **Pink Accent** | `#FF6B9D` | Reels, voice visualizers & emotion cues |
| **Red Accent** | `#EF4444` | Live stream indicator badges & broadcast buttons |
| **Text Primary** | `#FFFFFF` | Main headlines & high-contrast titles |
| **Text Subtitle** | `rgba(255,255,255,0.75)` | Crisp subtitles & secondary descriptions |
| **Title Typography** | Google Fonts **Rye** & **Outfit** | Expressive titles & modern body readability |
| **Glassmorphism** | `BackdropFilter` blur (24px) | Translucent frost overlays with subtle glowing borders |

---

## 🚀 Comprehensive Features & Screens

### ✨ Content Creation Studio & Floating FAB
Triggered by the glowing gradient `+` floating action button, this module offers four hand-crafted creation studios backed by `assets/normal_bg.png` theme background artwork:

1. **✍️ Post Composer Studio**:
   - User profile header (`Alex Quantum ✔️`) with audience selector (`🌐 Public Broadcast`).
   - High-contrast text editor with live AI Writer assist (`✨ AI Writer`), hashtag inserter (`#FutureVision`), and poll creator.
   - Real-time location geotagging using Geolocator GPS & reverse Geocoding placemark services.
   - Local media attachment storage utilizing local file paths directly inside `PostModel` structure.
   - Dynamic emoji panel overlay for fast character injection.

2. **📸 Story Studio**:
   - Interactive Phone Canvas live preview with customizable caption overlay.
   - 5-color vibe palette selector (`Cyan`, `Purple`, `Pink`, `Emerald`, `Gold`).
   - Interactive emoji sticker bar (`✨`, `🌌`, `🚀`, `🔥`, `⚡`, `💫`, `💎`, `👑`).
   - Prepends un-seen story ring to the top horizontal story bar.

3. **🎬 Reel Studio**:
   - Video thumbnail preview card with duration indicator (`00:15 HD`) and pulsing play button.
   - Audio track selector (`Quantum Beats 🎵`, `Deep Space Vibe 🌌`, `Synthwave Pulse ⚡`, `Cyber Ambient 🔮`).
   - Category selector chips (`Tech 🚀`, `AI & Future 🤖`, `Design 🎨`, `Gaming 🎮`).

4. **📡 Live Broadcast Studio**:
   - Camera Viewfinder preview box with corner reticles and red `● LIVE PREVIEW` badge.
   - Live stream statistics simulation (`👁️ 142 Viewers • 60 FPS`).
   - Control toggle chips (`🎤 Mic ON`, `📹 Cam ON`, `💬 Chat ON`).

---

### 🤖 ARIA AI Voice & Vision Companion
- **Real-Time Streaming Voice**: Microphones capture PCM audio bytes and stream directly via WebSocket to Deepgram Nova-2 STT.
- **Streaming LLM Token Delivery**: Answers stream token-by-token from Groq's `llama-3.1-8b-instant` model for instant responsiveness.
- **Multimodal Vision Analysis**: Attach photos from camera or gallery for visual reasoning with `llama-3.2-11b-vision-preview`.
- **Sequential Neural Speech (TTS)**: Synthesizes responses using Deepgram Aura-2 (`aura-2-helena-en`) with WAV byte array playback.
- **Neural Orb Animation**: 7-layer animated visualizer orb with pulsing rings and audio reactivity.

---

### 🗺️ Self-Hosted Map Engine
- **No Paid Maps**: Built using MapLibre GL JS, OpenFreeMap vector tiles, Nominatim geocoding, and OSRM turn-by-turn routing.
- **Native GPS Injection Bridge**: Overrides WebView browser geolocation using Flutter's native `Geolocator` plugin (`bestForNavigation` mode) for sub-meter navigation accuracy.
- **4 Map Visual Themes**: Dark, Light, Cyberpunk Neon, and Satellite imagery.
- **Turn-by-Turn HUD**: Real-time turn instruction overlay for Driving, Walking, and Cycling modes.

---

### 🎮 3D WebGL Open World Game
- **Embedded WebGL World**: Full 3D open-world adventure game rendered client-side via Three.js inside a Flutter WebView.
- **Exploration & Quests**: 3D character controls, planet environments, NPC interactions, ambient soundscapes, and full-screen canvas view.

---

### 📱 Quantum Social Feed & Feels
- **Quantum Feed**: Interactive social media feed featuring user avatars, verified badges, multi-image carousels, like/comment counter animations, and custom 3-dot post options modal (Share, Save, Copy Link, Mute, Report Post with reason selector).
- **Feels Short Videos**: Vertical full-screen swipe video reels with double-tap heart explosion animations, creator comments sheet, and audio track badges.
- **Bookmark & Collection Persistence**: Full support for local data caching via `SharedPreferences` to persistently save liked posts and reels.

---

### 💬 WebSocket Real-Time Chat Engine
- **Real-Time Messaging**: Built on Socket.IO client, supporting instantaneous message sync, typing indicators, and user online states.
- **Message Attachment Handlers**: Capture and attach photos from camera or gallery using native `ImagePicker`.
- **Reply Thread States**: Double-tap or swipe to reply to a message with a quoted preview window above the input box.
- **Chat Filtering & Inbox Layout**: Filter your inbox instantly between Primary and Requests, filter by Unread or Online users, and use active chat search.

---

### 📸 Camera & Live Filters
- **Real Hardware Integration**: Supports live camera preview, pinch-to-zoom, flash modes (Auto/On/Off/Torch), and self-timer countdowns.
- **MLKit Face Detection**: Real-time bounding box face detection powered by `google_mlkit_face_detection`.
- **6 Real-Time Color Filters**: Vivid, Matte, Cold, Warm, Black & White, and Vintage ColorMatrix presets.

---

### 🖼️ Immersive Dome & Timeline Gallery
- **Dome 360° Gallery**: Interactive spherical 360°-inspired visual photo browser.
- **River of Time**: Horizontal scrolling timeline view grouped by date.
- **Full-Screen Viewer**: Immersive photo inspector with pinch-to-zoom, gesture dismiss, native `share_plus` system sharing, and `image_gallery_saver` download utility.

---

## 📡 Unified Backend Services & Gateway

The backend architecture packages 4 Node.js services into a single unified Express gateway process running on port `10000`:

| Microservice | Port | Description |
|---|---|---|
| **Gateway Router** | `10000` | Multiplexes incoming HTTP & WebSocket requests to internal services |
| **ARIA AI Engine** | `3003` | Socket.IO server handling STT, LLM streaming & TTS audio synthesis |
| **Search Engine** | `3004` | REST API serving search queries, trending hashtags & discover items |
| **Game Server** | `3005` | Express static file server delivering the precompiled 3D WebGL bundle |
| **Map Engine** | `3006` | Proxies Nominatim geocoding & OSRM turn-by-turn routing requests |

---

## 📂 Project Directory Structure

```
Nexal_App/
├── lib/
│   ├── main.dart                              # Entrypoint & MaterialApp configuration
│   ├── theme/
│   │   └── app_theme.dart                    # Design system tokens, colors & gradients
│   ├── models/
│   │   └── post_model.dart                   # Post model schema with geolocation tags
│   ├── providers/
│   │   ├── feed_provider.dart                # Persistent bookmarks & feed state management
│   │   └── user_provider.dart                # Connection lists & dynamic follow state notifier
│   ├── services/
│   │   ├── aria_service.dart                 # Socket.IO client, streaming audio & chat handlers
│   │   └── api_service.dart                  # Centralized HTTP Client with Bearer token inject
│   ├── screens/
│   │   ├── home_view.dart                    # Quantum Feed, Post Options & Creation Studio Modals
│   │   ├── feels_view.dart                   # Vertical short video reels feed with SharedPreferences save
│   │   ├── messages_view.dart                # Chat inbox with search, tabs, & new conversation sheet
│   │   ├── camera_view.dart                  # Camera view with filters & MLKit face detection
│   │   ├── map_view.dart                     # Self-hosted MapLibre GL navigation map
│   │   ├── profile_view.dart                 # User profile, custom stats & clipboard share
│   │   ├── settings/
│   │   │   └── two_factor_screen.dart        # 2FA TOTP setup flow with QR codes
│   │   └── full_screen_image_view.dart       # Full-screen image viewer with share & gallery download
│   └── widgets/                              # Reusable components, backgrounds & glass cards
│
├── android/
│   └── build.gradle.kts                      # Kotlin DSL Gradle build script with subprojects AGP patch
│
└── Backend/
    ├── src/gateway.ts                        # Microservice unified gateway router
    ├── package.json                          # Unified build & startup scripts
    ├── aria_backend/                         # Groq & Deepgram AI microservice
    ├── search_backend/                       # Search REST API microservice
    ├── game_backend/                         # WebGL 3D game file server
    └── Map_Backend/                          # Nominatim & OSRM map server
```

---

## ⚡ Quick Start & Setup Guide

### 1. Prerequisites
- **Flutter SDK**: `>=3.10.7`
- **Dart SDK**: `>=3.10.7`
- **Node.js**: `>=20.x` & **npm**: `>=10.x`
- **Physical Device**: Strongly recommended for camera, microphone, gyroscope & GPS features.

### 2. Mobile App Setup (Flutter)
```bash
# Clone the repository
git clone https://github.com/aaweshdas/The-New-Era-_-Nexal-APP-.git
cd The-New-Era-_-Nexal-APP-

# Install Flutter dependencies
flutter pub get

# Run on physical device or emulator
flutter run
```

### 3. Backend Gateway Setup (Node.js)
```bash
# Navigate to the Backend folder
cd Backend

# Install all microservice dependencies
npm install

# Create environment configuration file
cp aria_backend/.env.example aria_backend/.env
```

Edit `Backend/aria_backend/.env`:
```env
GROQ_API_KEY=your_groq_api_key_here
DEEPGRAM_API_KEY=your_deepgram_api_key_here
PORT=3003
```

```bash
# Start all 4 backend microservices via Gateway (Port 10000)
npm run dev
```

---

## 🔑 Environment Variables & API Keys

| Location | Key Name | Description |
|---|---|---|
| **Backend `.env`** | `GROQ_API_KEY` | Groq LLM & Vision inference API key (Free at `console.groq.com`) |
| **Backend `.env`** | `DEEPGRAM_API_KEY` | Deepgram STT & TTS API key (Free at `console.deepgram.com`) |
| **In-App Settings** | `ARIA AI Config` | Enter API keys directly inside app UI via **Settings → ARIA AI Config** |

---

## 📦 Technical Dependencies

### Flutter Core Dependencies
- `flutter_animate` (`^4.5.2`): Chainable entry & continuous animations
- `google_fonts` (`^8.0.0`): Outfit (body text) & Rye (titles)
- `lucide_icons` (`^0.257.0`): Icon set
- `sensors_plus` (`^7.0.0`): Gyroscope tilt parallax tracking
- `camera` (`^0.12.0`): Camera preview, zoom & flash controls
- `google_mlkit_face_detection` (`^0.13.0`): On-device real-time face detection
- `geolocator` (`^13.0.2`): High-accuracy native GPS tracking (`bestForNavigation`)
- `webview_flutter` (`^4.13.1`): WebGL game & MapLibre GL map bridge
- `socket_io_client` (`^3.0.2`): Real-time WebSocket event communication
- `record` (`^6.2.1`): High-fidelity microphone PCM audio stream recording
- `audioplayers` (`^6.0.0`): Synthesized neural TTS WAV playback
- `share_plus` (`^10.1.4`): Native system sharing provider
- `image_gallery_saver` (`^2.0.3`): Image downloading and storage utility

---

## 📱 Platform Matrix & Requirements

| Platform | Support Status | Hardware Features |
|---|---|---|
| **Android** | ✅ Full Support | Native Camera, Microphone, High-Accuracy GPS, WebGL & Gyroscope |
| **iOS** | ✅ Full Support | Requires Xcode permissions setup in `Info.plist` |
| **Web** | ⚠️ Partial Support | Microphones require HTTPS connection |
| **Desktop (Win/Mac/Linux)** | ⚠️ Partial Support | Basic screens work; camera requires native desktop plugin drivers |

---

## 👤 Author & Credits

**Aawesh Das**
- GitHub: [@aaweshdas](https://github.com/aaweshdas)

---

<p align="center">
  <sub>Engineered with Flutter, Node.js & Deep Dark Aesthetic Design • 2026</sub>
</p>
