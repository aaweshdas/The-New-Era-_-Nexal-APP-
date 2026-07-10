<p align="center">
  <img src="assets/nexal_logo.png" width="130" alt="Nexal Logo" />
</p>

<h1 align="center">NEXAL</h1>

<p align="center">
  <em>A next-generation, AI-powered super app — engineered with Flutter, Node.js & a fully self-hosted mapping engine</em>
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

- [What is Nexal?](#-what-is-nexal)
- [Architecture Overview](#-architecture-overview)
- [Design Language](#-design-language)
- [Core Features & Screens](#-core-features--screens)
- [ARIA AI Companion — Deep Dive](#-aria-ai-companion--deep-dive)
- [Self-Hosted Map Engine](#-self-hosted-map-engine)
- [Unified Backend Gateway](#-unified-backend-gateway)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Backend Setup](#-backend-setup)
- [Environment Configuration](#-environment-configuration)
- [Dependencies](#-dependencies)
- [Platform Support](#-platform-support)
- [Author](#-author)

---

## ✦ What is Nexal?

**Nexal** is a premium, full-stack **super app** built with Flutter and backed by a real-time Node.js/TypeScript multi-service backend. It pushes the limits of what a production-quality mobile app can look and feel like — combining a deep-space dark aesthetic with live AI, a fully self-hosted navigation engine, a 3D WebGL game, and a rich social media experience.

Nexal ships with **four real backend services** that all run simultaneously through a unified gateway:

| Service | Description |
|---|---|
| **ARIA AI Backend** | Real-time voice, LLM streaming, Text-to-Speech via Groq & Deepgram |
| **Search Backend** | REST API powering the Explore & Search feature |
| **Map Backend** | Self-hosted map API server — geocoding, routing, POI search |
| **Game Backend** | Express file server for the embedded 3D WebGL game |

---

## 🏗️ Architecture Overview

```
┌──────────────────────────────────────────────────────┐
│                  Flutter App (Phone)                  │
│                                                       │
│  ┌──────────┐  ┌───────────┐  ┌────────────────────┐ │
│  │ Screens  │  │  Widgets  │  │     Services       │ │
│  │ 19 full  │  │ Reusable  │  │ AriaService        │ │
│  │ screens  │  │ UI comps  │  │ AriaConfig         │ │
│  └──────────┘  └───────────┘  └────────┬───────────┘ │
│                                        │              │
│  ┌────────────────────────────────┐    │ Socket.IO   │
│  │    WebView (Map + Game)        │    │ + HTTP      │
│  │  MapLibre GL / WebGL renderer  │    │             │
│  └────────────────────────────────┘    │             │
└────────────────────────────────────────│─────────────┘
                                         │
┌────────────────────────────────────────│─────────────┐
│              Unified Gateway (Node.js)                │
│              Deployed on Render.com                   │
│                                                       │
│  Public port (10000) — single Render URL              │
│                                                       │
│  /map/*   → Map Backend     (internal :3006)         │
│  /api/*   → Search Backend  (internal :3004)         │
│  /game/*  → Game Backend    (internal :3005)         │
│  /*       → ARIA Backend    (internal :3003)         │
│                                                       │
│  ┌────────────┐ ┌────────────┐ ┌──────┐ ┌─────────┐  │
│  │ARIA Backend│ │Map Backend │ │Search│ │  Game   │  │
│  │Socket.IO   │ │Express API │ │ API  │ │ Server  │  │
│  │Groq + Deep │ │Nominatim + │ │      │ │ WebGL   │  │
│  │gram STT/TTS│ │OSRM proxy  │ │      │ │ Static  │  │
│  └────────────┘ └────────────┘ └──────┘ └─────────┘  │
└───────────────────────────────────────────────────────┘
```

**Key architectural decisions:**
- **Single Render URL** — all four backend services are multiplexed through one unified gateway
- **Socket.IO** for bidirectional real-time communication between Flutter and ARIA
- **Streaming STT** — audio chunks stream directly to Deepgram for near-zero-latency transcription
- **Streaming LLM** — Groq responses are streamed chunk-by-chunk for a live "typing" effect
- **Self-hosted maps** — 100% free OpenStreetMap tiles via MapLibre GL — no Google Maps, no paid APIs
- **GPS injection bridge** — Flutter's native `Geolocator` (high-accuracy) injects live coordinates directly into the WebView via JavaScript, bypassing the browser's lower-accuracy geolocation API

---

## 🎨 Design Language

Nexal enforces a strict, futuristic design system across every screen:

| Token | Value |
|---|---|
| **Background** | Near-black `#0A0A0F` (deep space) |
| **Surface** | `#141420` (elevated cards) |
| **Surface Light** | `#1E1E2E` (interactive containers) |
| **Primary Accent** | Purple `#B07CFF` |
| **Accent Dim** | `#8B5CF6` (buttons, gradients) |
| **Accent Bright** | `#D4BBFF` (highlights) |
| **Pink** | `#FF6B9D` (voice/emotion cues) |
| **Cyan** | `#67E8F9` (status indicators) |
| **Text Primary** | `#F1F0F5` (main content) |
| **Text Secondary** | `#9CA3AF` (subtitles) |
| **Text Muted** | `#6B7280` (placeholders, timestamps) |
| **Border** | `#2A2A3E` (card outlines) |
| **Title Font** | Google Fonts **Rye** |
| **Body Font** | Google Fonts **Outfit** |
| **Cards** | Glassmorphic — `BackdropFilter` blur, `rgba` translucent fill, thin border |
| **Entry Animations** | `flutter_animate` — fade, slide, scale per-widget |
| **Continuous Animations** | Custom `AnimationController` — orb breathing, wave pulses |

**Design Principles:**
1. **Every pixel is intentional** — no default Flutter widgets are left unstyled
2. **Micro-animations everywhere** — hover states, press feedback, shimmer loaders
3. **Premium first-impression** — cinematic splash video on every cold launch
4. **Gyroscope-driven depth** — parallax effects respond to physical device tilt

---

## 🚀 Core Features & Screens

### 🌌 Splash Screen
- Full-screen cinematic **startup video** (`startup.mp4`) plays on launch
- Auto-advances to the Galaxy Hub after completion
- `VideoPlayerController` with aspect-ratio-preserving `BoxFit`

### 🌀 Galaxy Hub (Home Screen)
- **Orbital navigation wheel** — icons orbit the center with spring-physics positioning
- **Looping deep-space video background** (`Background.mp4`)
- **Gyroscope parallax** — background shifts subtly as you tilt the device
- Spring-loaded press animations on all navigation elements

### 📱 Quantum Feed (Social Feed)
- AI-curated post cards with user avatars, gradients, and interaction buttons
- **Like, Comment, Share, Bookmark** with animated state changes
- Trending topics bar with chip-style scrollable filters
- Live status bar showing online users
- **Shimmer skeleton loaders** while posts load
- `CachedNetworkImage` for all avatars and post images

### 🎬 Feels (Short Video Reels)
- Vertical-scrolling short video feed (TikTok-style)
- **Double-tap to like** with animated heart burst effect
- Comment sheet, share options, follow button per creator
- Smooth `PageView.builder` with custom transitions

### 💬 Messages & Chat
- **Dual-tab inbox** — Primary and Requests conversations
- **Swipe-to-dismiss** with confirmation for deleting conversations
- Individual chat thread with emoji picker, attachment options, typing indicator, and AI auto-reply suggestions

### 🎥 Video Hub
- **Continue Watching** row with animated progress rings
- Trending rankings with rank-change indicators
- Category browsing with horizontal scroll chips

### 📷 Camera
- **Live camera preview** with real hardware integration
- **Pinch-to-zoom** gesture with `CameraController.setZoomLevel`
- **Flash mode cycling** — Auto / On / Off / Torch
- **Self-timer** — 3s / 5s / 10s countdown with overlay
- **Grid overlay** — rule-of-thirds composition guide
- **Face detection** via `google_mlkit_face_detection`
- **6 real-time color filters** — Vivid, Matte, Cold, Warm, B&W, Vintage
- **4 capture modes** — Photo, Video, Portrait, Slow-Mo

### 🔍 Explore & Search
- Animated **nebula particle background**
- Live-filtered search results from the Search Backend REST API
- **Trending topics** with rank positions and change badges
- **Masonry grid** (`flutter_staggered_grid_view`) of discovery content

### 🤖 ARIA AI Companion
> See the dedicated [ARIA section](#-aria-ai-companion--deep-dive) below.

### 🗺️ Map (Navigation)
> See the dedicated [Map Engine section](#-self-hosted-map-engine) below.

### 🎮 Open World Games (Arcade Hub)
- Curated selection of games accessible within the app
- Game card UI with glassmorphic styling and launch animations
- Navigates to the embedded 3D WebGL game

### 🌍 3D WebGL Game (Messenger)
- A full **3D open-world exploration game** embedded inside the app via a WebView
- Served from the Game Backend on the Render server
- GPU-rendered client-side WebGL (Three.js engine)
- Full 3D characters, planet environments, NPC quests, ambient audio
- Edge-to-edge immersive canvas — zero UI chrome

### 👤 Profile
- Editable profile fields with inline save
- Achievement badge system with unlock animations
- **4-tab content grid** — Posts, Reels, Liked, Saved
- Privacy & notification settings panel

### 🖼️ Gallery & Gallery Viewer
- **Premium timeline layout** — grouped by date with section headers
- **Immersive Dome Gallery** — 360°-inspired circular image browser
- **River of Time** — horizontal scrolling cinematic timeline
- **Full-screen image viewer** with pinch-to-zoom, swipe-to-dismiss

---

## 🤖 ARIA AI Companion — Deep Dive

ARIA (Adaptive Responsive Intelligence Assistant) is Nexal's built-in AI companion with real-time voice, text, and vision capabilities.

### Features

| Feature | Description |
|---|---|
| **Live Voice Input** | Stream microphone audio to Deepgram Nova-2 STT in real-time |
| **Text Input** | Type messages; supports multiline input |
| **Image Attachment** | Attach images from Gallery or Camera; ARIA analyzes them visually |
| **Streaming Responses** | LLM text streams chunk-by-chunk for a live "typing" effect |
| **Text-to-Speech** | Responses synthesized with Deepgram Aura TTS, played back sequentially |
| **Chat History** | All conversations saved locally with `SharedPreferences` |
| **New Chat** | Start a fresh conversation; current chat auto-saves to history |
| **Message Actions** | Copy, Share, or have ARIA read any message aloud |
| **Quick Suggestions** | Prompt cards for common tasks (Write, Explain, Code, Translate) |

### UI Design
- **7-layer animated neural orb** — breathing, pulsing glow with gradient rings
- **Live waveform visualizer** during voice input
- **Glassmorphic chat bubbles** with frosted backdrop blur
- **Streaming text cursor** blinking while ARIA is typing
- **Connection status dot** (green = live, red = offline)

### Backend Events (Socket.IO Protocol)

```
Client → Server
────────────────────────────────────────────
audio_stream       Send raw PCM audio bytes (16-bit, 16kHz, mono)
stop_audio_stream  Signal end of microphone session
text_input         { text: string, image?: string (base64 data URL) }
trigger_tts        { text: string } — read specific text aloud
clear_history      Reset conversation context for this session
update_config      { groq_api_key, deepgram_api_key } — hot-swap keys

Server → Client
────────────────────────────────────────────
connected          Handshake confirmation
transcript         { text, hasImage?, timestamp } — live STT result
processing_start   LLM has started generating
aria-stream-chunk  A single token/word from the LLM stream
ai_response        { text, timestamp } — full completed response
tts_start          TTS synthesis has begun
tts_audio          Binary audio data (WAV) — one chunk per sentence
tts_end            All TTS audio for this response has been sent
error              { message, detail }
```

### AI Models

| Role | Model | Provider |
|---|---|---|
| Text conversations | `llama-3.1-8b-instant` | Groq |
| Vision (image + text) | `llama-3.2-11b-vision-preview` | Groq |
| Speech-to-Text | `nova-2` (streaming WebSocket) | Deepgram |
| Text-to-Speech | `aura-2-helena-en` | Deepgram |

---

## 🗺️ Self-Hosted Map Engine

Nexal's map feature is a **100% self-hosted navigation system** — no Google Maps, no paid mapping APIs of any kind.

### Technology Stack

| Layer | Technology | Description |
|---|---|---|
| **Map Renderer** | MapLibre GL JS | GPU-accelerated vector tile renderer |
| **Map Tiles** | OpenFreeMap (OpenStreetMap data) | Free, self-hostable vector tiles |
| **Geocoding** | Nominatim | Free address search & autocomplete |
| **Turn-by-Turn Routing** | OSRM | Open-source routing engine |
| **Frontend** | React + Vite (TypeScript) | Compiled to static assets embedded in Flutter |
| **Backend API** | Express (Node.js) | Proxies map API calls server-side |
| **GPS** | Flutter `Geolocator` (native) | Injects high-accuracy coordinates into WebView |

### Map Features

| Feature | Description |
|---|---|
| **4 Map Themes** | Dark, Light, Cyberpunk neon, Satellite |
| **Real-Time Location** | Pulsing GPS dot follows your position in real-time |
| **High-Accuracy GPS** | Native Flutter `Geolocator` at `bestForNavigation` precision |
| **Address Search** | Debounced Nominatim autocomplete with categorized results |
| **Turn-by-Turn Navigation** | OSRM routing for Driving, Walking, and Cycling |
| **Navigation HUD** | Live turn instruction overlay during route |
| **POI Search** | Category-based nearby points-of-interest search |
| **Smooth Pan & Zoom** | 60fps MapLibre GL with optimized pixel ratio cap |
| **Glassmorphic UI** | All overlays use `backdrop-filter: blur(24px)` frosted glass |

### How GPS Works Inside the App

The Flutter app intercepts browser geolocation calls and replaces them with native GPS:

```
Device GPS Hardware
  → Flutter Geolocator (native, bestForNavigation accuracy)
  → window.__nexalGPSUpdate(lat, lng, accuracy) [JS injection]
  → MapLibre GL (updates user dot position every 2 metres)
```

This bypasses the lower-accuracy browser geolocation API, giving navigation-grade precision inside a WebView.

### Map Backend API Endpoints

All map API calls are proxied through the Map Backend server (no CORS issues, no client-side API exposure):

| Endpoint | Description |
|---|---|
| `GET /map/health` | Service health check |
| `GET /map/geocode?q=...` | Address search via Nominatim |
| `GET /map/autocomplete?q=...` | Search suggestions |
| `GET /map/route?startLat=&startLng=&endLat=&endLng=&mode=` | OSRM routing (driving/walking/cycling) |
| `GET /map/nearby?lat=&lon=&q=&radius=` | POI search around a location |

---

## 🔗 Unified Backend Gateway

All four backend services are launched together through a single **gateway process** and exposed on one public URL on Render.

### Starting All Backends (Local Dev)

```bash
cd Backend
npm run dev
# Spawns: ARIA (3003) + Search (3004) + Game (3005) + Map (3006)
# Opens gateway at: http://localhost:10000
```

### Individual Service Dev Commands

```bash
npm run aria     # ARIA AI backend only
npm run search   # Search backend only
npm run game     # Game backend only
npm run map      # Map backend only
```

### Gateway Routing Table

| URL Path | Target Service | Internal Port |
|---|---|---|
| `/map/*` | Map Backend | 3006 |
| `/api/*`, `/search` | Search Backend | 3004 |
| `/game/*` | Game Backend | 3005 |
| `/*` | ARIA Backend | 3003 |

### Render Deployment

The root `nixpacks.toml` configures Render to:
1. `npm install` — installs all 4 backend dependencies via `postinstall`
2. `npm run build` — compiles all 4 TypeScript backends
3. `npm start` — launches the unified gateway

Set one Render service pointing to the `Backend/` root directory. One URL handles everything.

---

## 📁 Project Structure

```
Nexal_App/
│
├── lib/                                       # Flutter application source
│   ├── main.dart                              # App entrypoint, MaterialApp config
│   │
│   ├── theme/
│   │   └── app_theme.dart                    # Global ThemeData, colors, gradients
│   │
│   ├── utils/
│   │   └── filter_generator.dart             # Camera color filter ColorMatrix presets
│   │
│   ├── services/
│   │   ├── aria_service.dart                 # Socket.IO client singleton, event streams
│   │   └── aria_config.dart                  # Local config store (API keys via SharedPrefs)
│   │
│   ├── screens/
│   │   ├── splash_video_screen.dart          # Launch cinematic
│   │   ├── home_screen.dart                  # Galaxy Hub + orbital navigation wheel
│   │   ├── home_view.dart                    # Quantum Feed (social posts)
│   │   ├── feels_view.dart                   # Short vertical video reels
│   │   ├── messages_view.dart                # DM inbox — primary & requests tabs
│   │   ├── chat_screen.dart                  # Individual conversation thread
│   │   ├── video_view.dart                   # Video streaming hub
│   │   ├── camera_view.dart                  # Camera capture with filters & face detection
│   │   ├── camera_preview_screen.dart        # Post-capture review screen
│   │   ├── search_view.dart                  # Explore / discover / search
│   │   ├── ai_assist_view.dart               # ARIA AI chat interface
│   │   ├── map_view.dart                     # Self-hosted navigation map
│   │   ├── open_world_games_view.dart        # Arcade hub / game selection
│   │   ├── game_webview_screen.dart          # Embedded 3D WebGL game screen
│   │   ├── profile_view.dart                 # User profile & settings
│   │   ├── gallery_view.dart                 # Photo gallery with multiple views
│   │   ├── full_screen_image_view.dart       # Immersive full-screen image viewer
│   │   ├── immersive_dome_gallery_view.dart  # 360° dome-style gallery
│   │   └── monthly_timeline_view.dart        # Date-grouped timeline gallery
│   │
│   └── widgets/
│       ├── background/                       # Video player + particle backgrounds
│       ├── common/                           # PostCard, GlassEmptyState, etc.
│       ├── effects/                          # GyroParallaxWrapper
│       ├── gallery/                          # DomeGallery, RiverOfTime widgets
│       ├── navigation/                       # QuantumArcMenu, nav items
│       ├── notifications/                    # Notification bottom sheet
│       └── settings/                         # Settings modal
│
├── assets/
│   ├── nexal_logo.png                        # App icon
│   ├── videos/
│   │   ├── Background.mp4                    # Looping background for Galaxy Hub
│   │   └── startup.mp4                       # Cinematic splash video
│   ├── map/                                  # Compiled React map frontend (auto-generated)
│   ├── wordl/                                # Embedded WebGL game assets
│   ├── nav_icons/                            # Custom navigation icon assets
│   └── gallery/                              # Sample gallery images
│
├── Backend/                                  # All backend services
│   │
│   ├── src/gateway.ts                        # Unified gateway — spawns all 4 services
│   ├── package.json                          # Root: install + build + start all services
│   ├── nixpacks.toml                         # Render deployment configuration
│   │
│   ├── aria_backend/                         # ARIA AI service (port 3003)
│   │   ├── src/index.ts                      # Express + Socket.IO server
│   │   └── src/services/
│   │       ├── groq.service.ts               # LLM streaming + TTS queue
│   │       └── deepgram.service.ts           # STT WebSocket + TTS REST
│   │
│   ├── search_backend/                       # Search REST API (port 3004)
│   │   └── src/index.ts
│   │
│   ├── game_backend/                         # Game file server (port 3005)
│   │   └── src/index.ts                      # Express — serves game_frontend/
│   │
│   ├── game_frontend/                        # Pre-compiled WebGL game bundle
│   │   ├── index.html                        # Game entry point
│   │   └── assets/                           # JS, audio, geometries, textures, fonts
│   │
│   └── Map_Backend/                          # Map service
│       ├── src/                              # React frontend source (Vite + MapLibre GL)
│       ├── server/index.ts                   # Express Map API server (port 3006)
│       ├── dist/                             # Compiled React output → copied to assets/map
│       └── tsconfig.server.json              # Server-side TypeScript config
│
├── android/                                  # Android native project
├── ios/                                      # iOS native project
├── web/                                      # Web platform project
├── windows/                                  # Windows desktop project
├── linux/                                    # Linux desktop project
├── macos/                                    # macOS desktop project
└── pubspec.yaml                              # Flutter dependencies & asset config
```

---

## ⚙️ Getting Started

### Prerequisites

| Requirement | Version |
|---|---|
| Flutter SDK | `>=3.10.7` |
| Dart SDK | `>=3.10.7` |
| Node.js | `>=20.x` |
| npm | `>=10.x` |
| Android Studio / Xcode | Latest stable |
| Physical device | Strongly recommended |

> **Tip:** A physical device is strongly recommended. Gyroscope parallax, camera filters, GPS tracking, and microphone streaming are either unavailable or degraded on emulators.

---

### Step 1 — Clone the repository

```bash
git clone https://github.com/aaweshdas/The-New-Era-_-Nexal-APP-.git
cd The-New-Era-_-Nexal-APP-
```

### Step 2 — Install Flutter dependencies

```bash
flutter pub get
```

### Step 3 — Run the Flutter app

```bash
flutter run
```

The full UI will launch immediately. Social feed, messages, gallery, camera, and game features work without any backend.

---

## 🖥️ Backend Setup

All four backend services start with a **single command** from the `Backend/` directory.

### Step 1 — Navigate to the backend

```bash
cd Backend
```

### Step 2 — Install all backend dependencies

```bash
npm install
# Automatically installs dependencies for all 4 sub-backends via postinstall
```

### Step 3 — Configure API keys

Create `Backend/aria_backend/.env`:

```env
# Groq API key — free at console.groq.com
GROQ_API_KEY=your_groq_api_key_here

# Deepgram API key — free at console.deepgram.com
DEEPGRAM_API_KEY=your_deepgram_api_key_here

# Server port (default: 3003)
PORT=3003
```

> **Note:** You can also enter API keys directly in the app via **Settings → ARIA AI Config**. They are pushed to the backend over Socket.IO and saved locally without restarting the server.

### Step 4 — Start all backends (development)

```bash
npm run dev
```

This launches the unified gateway which spawns all four backend services simultaneously:

```
[Gateway] Spawned ARIA   → internal port 3003
[Gateway] Spawned SEARCH → internal port 3004
[Gateway] Spawned GAME   → internal port 3005
[Gateway] Spawned MAP    → internal port 3006
[Gateway] ✓ All backends ready
═══════════════════════════════════════════════════════
  Nexal Backend Gateway — LIVE
  Public Port : 10000
  /map/*      → Map Backend    (localhost:3006)
  /api/*      → Search Backend (localhost:3004)
  /game/*     → Game Backend   (localhost:3005)
  /*          → ARIA Backend   (localhost:3003)
═══════════════════════════════════════════════════════
```

### Step 5 — Verify services are running

```bash
curl http://localhost:10000/health          # ARIA health
curl http://localhost:10000/map/health      # Map health
curl http://localhost:10000/game/api/status # Game health
```

### Backend Scripts

| Command | Description |
|---|---|
| `npm run dev` | Start all 4 backends via unified gateway (development) |
| `npm run build` | Compile all 4 TypeScript backends to `dist/` |
| `npm start` | Run compiled production gateway |
| `npm run aria` | Start ARIA backend only |
| `npm run search` | Start Search backend only |
| `npm run game` | Start Game backend only |
| `npm run map` | Start Map backend only |

### Building & Deploying the Map Frontend

The Map frontend is a React/Vite app that must be compiled and copied to Flutter assets:

```bash
# Build the React map frontend
cd Backend/Map_Backend
npm run build

# Copy compiled output to Flutter assets
cd ../..
Remove-Item -Recurse -Force "assets/map/*"
Copy-Item -Path "Backend/Map_Backend/dist/*" -Destination "assets/map" -Recurse -Force
```

---

## 🔐 Environment Configuration

### Backend (`aria_backend/.env`)

| Variable | Required | Description |
|---|---|---|
| `GROQ_API_KEY` | ✅ Yes | Groq API key for LLM (`llama-3.1-8b-instant`) and vision (`llama-3.2-11b-vision-preview`) |
| `DEEPGRAM_API_KEY` | ✅ Yes | Deepgram key for Nova-2 streaming STT and Aura-2 TTS |
| `PORT` | ❌ Optional | Server port (default: `3003`) |

### Flutter (stored via `shared_preferences`)

| Key | Description |
|---|---|
| `aria_backend_url` | URL of the ARIA backend (default: `http://localhost:3003`) |
| `aria_groq_key` | Groq API key entered in-app |
| `aria_deepgram_key` | Deepgram API key entered in-app |
| `aria_chat_history` | JSON-encoded list of past ARIA conversations |

---

## 📦 Dependencies

### Flutter (Frontend)

| Package | Version | Purpose |
|---|---|---|
| `flutter_animate` | `^4.5.2` | Chainable entry and continuous animations |
| `google_fonts` | `^8.0.0` | Outfit (body), Rye (titles) |
| `lucide_icons` | `^0.257.0` | Crisp, consistent icon set |
| `glassmorphism_ui` | `^0.3.0` | Frosted glass `BackdropFilter` containers |
| `sensors_plus` | `^7.0.0` | Gyroscope data for parallax effects |
| `flutter_staggered_grid_view` | `^0.7.0` | Masonry grid layouts |
| `video_player` | `^2.11.0` | Splash cinematic + looping video backgrounds |
| `camera` | `^0.12.0` | Live camera preview, flash, zoom, filters |
| `google_mlkit_face_detection` | `^0.13.0` | Real-time on-device face detection |
| `permission_handler` | `^12.0.1` | Runtime permissions (camera, microphone, location) |
| `image_picker` | `^1.2.1` | Gallery/camera image selection for ARIA |
| `provider` | `^6.1.5` | State management |
| `shared_preferences` | `^2.5.5` | Local persistence (ARIA config, chat history) |
| `cached_network_image` | `^3.4.1` | Disk-cached image loading |
| `shimmer` | `^3.0.0` | Skeleton loading animations |
| `socket_io_client` | `^3.0.2` | WebSocket/Socket.IO for ARIA backend |
| `record` | `^6.2.1` | Microphone streaming in PCM format |
| `audioplayers` | `^6.0.0` | TTS audio playback from WAV byte data |
| `webview_flutter` | `^4.13.1` | Embeds React map & WebGL game inside Flutter |
| `webview_flutter_android` | `^4.12.0` | Android-specific WebView configuration |
| `geolocator` | `^13.0.2` | High-accuracy native GPS (`bestForNavigation`) |
| `http` | `^1.2.0` | HTTP requests |
| `url_launcher` | `^6.3.1` | Open external URLs |
| `speech_to_text` | `^7.0.0` | On-device speech recognition |
| `flutter_launcher_icons` | `^0.14.3` | Adaptive app icons for all platforms |
| `cupertino_icons` | `^1.0.8` | iOS-style system icons |

### Node.js Backend

| Package | Purpose |
|---|---|
| `express` | HTTP server and REST API |
| `socket.io` | Bidirectional real-time event transport |
| `groq-sdk` | Official Groq SDK for streaming LLM completions |
| `dotenv` | Environment variable loading |
| `cors` | Cross-origin request headers |
| `ws` | Native WebSocket client for Deepgram STT |
| `http-proxy` | Gateway proxy for routing between services |
| `tsx` | TypeScript hot-reload for development |
| `typescript` | Type-safe backend development |

### Map Frontend

| Package | Purpose |
|---|---|
| `maplibre-gl` | GPU-accelerated vector map renderer |
| `react` + `react-dom` | UI component framework |
| `framer-motion` | Smooth UI animations |
| `zustand` | Lightweight state management |
| `@tanstack/react-query` | Async data fetching |
| `vite` | Fast build tool and dev server |

---

## 📱 Platform Support

| Platform | Status | Notes |
|---|---|---|
| **Android** | ✅ Full Support | Primary target. All features including camera, GPS, microphone, WebView work natively. |
| **iOS** | ✅ Full Support | Requires Xcode. Add microphone, camera, location usage descriptions to `Info.plist`. |
| **Web** | ⚠️ Partial | Camera and microphone require HTTPS. Gyroscope may be limited by browser permissions. |
| **Windows** | ⚠️ Partial | Camera and microphone require native plugin support. |
| **macOS** | ⚠️ Partial | Requires microphone/camera entitlements in `*.entitlements`. |
| **Linux** | ⚠️ Partial | Camera plugin support is experimental. |

---

## 📝 Notes & Caveats

- **Social feed data is mocked** — avatars from Unsplash, post images from Picsum Photos; all users are generated locally
- **ARIA requires a live backend** — LLM, STT, and TTS are not available without running the backend
- **Camera features are real** — flash, zoom, timer, face detection, and color filters all use actual device hardware
- **Map works offline** — after map tiles are cached in the WebView, the map renders without internet; geocoding and routing still require connectivity
- **Game runs on device** — the WebGL game is client-side rendered (JavaScript + GPU). The Game Backend only serves the static files
- **API Keys are free** — Groq and Deepgram both offer generous free tiers; no credit card required
- **Chat history is local-only** — ARIA conversations are stored via `shared_preferences`, not synced to any cloud
- **Conversation context** — ARIA maintains up to 20 messages of rolling context per session. "New Chat" resets context

---

## 👤 Author

**Aawesh Das**
GitHub: [@aaweshdas](https://github.com/aaweshdas)

---

<p align="center">
  <sub>Built with ☕, Flutter, and a deep love of dark UIs • 2026</sub>
</p>
