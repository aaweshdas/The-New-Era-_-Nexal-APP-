<p align="center">
  <img src="assets/nexal_logo.png" width="140" alt="Nexal Logo" />
</p>

<h1 align="center">NEXAL — Super App Studio</h1>

<p align="center">
  <em>A flagship, next-generation AI super app engine — built with Flutter, Node.js, WebGL 3D & a self-hosted OpenStreetMap engine.</em>
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

- [✦ Overview](#-overview)
- [🏗️ System Architecture](#️-system-architecture)
- [🎨 Design Language & Aesthetic System](#-design-language--aesthetic-system)
- [🚀 Comprehensive Features & Screens](#-comprehensive-features--screens)
  - [✨ Content Creation Studio & Floating FAB](#-content-creation-studio--floating-fab)
  - [🤖 ARIA AI Voice & Vision Companion](#-aria-ai-voice--vision-companion)
  - [🗺️ Self-Hosted Map Engine](#-self-hosted-map-engine)
  - [🎮 3D WebGL Open World Game](#-3d-webgl-open-world-game)
  - [📱 Quantum Social Feed & Feels](#-quantum-social-feed--feels)
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

## ✦ Overview

**Nexal** is a production-grade, full-stack **super app** powered by Flutter on the frontend and backed by a real-time Node.js/TypeScript multi-service backend gateway. It merges high-end glassmorphic UI design, real-time AI voice streaming, a self-hosted vector tile navigation engine, a 3D WebGL open-world game, and a suite of interactive social media tools into a single experience.

### Why Nexal?
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
   - Sample visual media selector grid with glowing checkmark indicators.
   - Instantly prepends published posts to top of the Quantum Feed.

2. **📸 Story Studio**:
   - Interactive Phone Canvas live preview with customizable caption overlay.
   - 5-color vibe palette selector (`Cyan`, `Purple`, `Pink`, `Emerald`, `Gold`).
   - Interactive emoji sticker bar (`✨`, `🌌`, `🚀`, `🔥`, `⚡`, `💫`, `💎`, `👑`).
   - Prepends un-seen story ring to the top horizontal story bar.

3. **🎬 Reel Studio**:
   - Video thumbnail preview card with duration indicator (`00:15 HD`) and pulsing play button.
   - Audio track selector (`Quantum Beats 🎵`, `Deep Space Vibe 🌌`, `Synthwave Pulse ⚡`, `Cyber Ambient 🔮`).
   - Category selector chips (`Tech 🚀`, `AI & Future 🤖`, `Design 🎨`, `Gaming 🎮`).
   - Publishes short video reel directly into the social feed.

4. **📡 Live Broadcast Studio**:
   - Camera Viewfinder preview box with corner reticles and red `● LIVE PREVIEW` badge.
   - Live stream statistics simulation (`👁️ 142 Viewers • 60 FPS`).
   - Control toggle chips (`🎤 Mic ON`, `📹 Cam ON`, `💬 Chat ON`).
   - Stream title composer and broadcast launch trigger.

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
- **Saved Posts Drawer**: Fast access to saved content using custom `assets/saved_icon.png`.

---

### 📸 Camera & Live Filters
- **Real Hardware Integration**: Supports live camera preview, pinch-to-zoom, flash modes (Auto/On/Off/Torch), and self-timer countdowns.
- **MLKit Face Detection**: Real-time bounding box face detection powered by `google_mlkit_face_detection`.
- **6 Real-Time Color Filters**: Vivid, Matte, Cold, Warm, Black & White, and Vintage ColorMatrix presets.

---

### 🖼️ Immersive Dome & Timeline Gallery
- **Dome 360° Gallery**: Interactive spherical 360°-inspired visual photo browser.
- **River of Time**: Horizontal scrolling timeline view grouped by date.
- **Full-Screen Viewer**: Immersive photo inspector with pinch-to-zoom and gesture dismiss.

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
│   ├── utils/
│   │   └── filter_generator.dart             # Camera color filter matrix generators
│   ├── services/
│   │   ├── aria_service.dart                 # Socket.IO client, streaming audio & chat handlers
│   │   └── aria_config.dart                  # SharedPreferences local storage & API keys
│   ├── screens/
│   │   ├── splash_video_screen.dart          # Startup cinematic video player
│   │   ├── home_screen.dart                  # Galaxy Hub + orbital arc navigation
│   │   ├── home_view.dart                    # Quantum Feed, Post Options & Creation Studio Modals
│   │   ├── feels_view.dart                   # Vertical short video reels feed
│   │   ├── messages_view.dart                # Chat inbox (Primary & Requests)
│   │   ├── chat_screen.dart                  # Interactive messaging thread
│   │   ├── video_view.dart                   # Video streaming hub
│   │   ├── camera_view.dart                  # Camera view with filters & MLKit face detection
│   │   ├── search_view.dart                  # Search & trending topics API view
│   │   ├── ai_assist_view.dart               # ARIA AI Chat studio interface
│   │   ├── map_view.dart                     # Self-hosted MapLibre GL navigation map
│   │   ├── open_world_games_view.dart        # Arcade hub
│   │   ├── game_webview_screen.dart          # 3D WebGL embedded game view
│   │   ├── profile_view.dart                 # User profile & badge achievements
│   │   ├── gallery_view.dart                 # Multi-view photo gallery
│   │   ├── full_screen_image_view.dart       # Full-screen image zoom viewer
│   │   ├── immersive_dome_gallery_view.dart  # 360° Dome gallery browser
│   │   └── monthly_timeline_view.dart        # Timeline-grouped photo gallery
│   └── widgets/                              # Reusable components, backgrounds & glass cards
│
├── assets/
│   ├── nexal_logo.png                        # App logo
│   ├── normal_bg.png                         # Studio modal starry mountain background
│   ├── saved_icon.png                        # Custom bookmark asset icon
│   ├── videos/                               # Startup.mp4 & Background.mp4
│   ├── map/                                  # Compiled React map frontend
│   └── wordl/                                # 3D WebGL game assets
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
