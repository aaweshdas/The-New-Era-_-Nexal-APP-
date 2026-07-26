<p align="center">
  <img src="assets/nexal_logo.png" width="120" alt="Nexal Logo" />
</p>

<h1 align="center">Nexal</h1>

<p align="center">
  <strong>One app. Everything you need.</strong><br/>
  <sub>A unified super app — social feed, AI assistant, self-hosted navigation, 3D gaming, real-time messaging, and smart camera in a single install.</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=flat-square&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.10+-0175C2?style=flat-square&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Node.js-20+-339933?style=flat-square&logo=node.js&logoColor=white" />
  <img src="https://img.shields.io/badge/TypeScript-5.4+-3178C6?style=flat-square&logo=typescript&logoColor=white" />
  <img src="https://img.shields.io/badge/Supabase-Supported-3ECF8E?style=flat-square&logo=supabase&logoColor=white" />
  <img src="https://img.shields.io/badge/License-MIT-EC4899?style=flat-square" />
</p>

---

## 📌 Overview

**Nexal** is a Flutter-based super app that consolidates six core digital experiences into a single lightweight application powered by a unified Node.js microservices gateway:

1. **Social Feed & Short Video Reels ("Feels")**: Posts, short video reels, stories, comments, bookmarks, and user engagement tracking.
2. **ARIA Voice AI Assistant**: Low-latency voice-to-voice interaction powered by Deepgram STT, Groq LLM, and Deepgram TTS over WebSockets.
3. **Self-Hosted Navigation**: MapLibre GL engine with turn-by-turn routing using Nominatim and OSRM (zero external API fees).
4. **3D Open-World Gaming**: Embedded WebGL game client and Luanti engine rendered via Flutter WebViews.
5. **Real-time Messaging**: Socket.IO powered messaging with media attachments, reply threads, and voice bubbles.
6. **Smart Camera & Immersive Gallery**: Real-time camera preview with Google ML Kit Face Detection, live color filters, 360° Dome View, River of Time, and timeline galleries.

---

## 🚀 Key Features & Modules

| Module | Description | Key Technologies |
|---|---|---|
| **Social Feed & Reels** | Infinite scroll feed, short video reels ("Feels"), story viewer, comments, and post creation | `provider`, `video_player`, `cached_network_image` |
| **ARIA AI Assistant** | Low-latency voice-to-voice conversational AI engine | Deepgram STT/TTS, Groq LLM, `record`, `audioplayers`, WebSockets |
| **Navigation & Maps** | Interactive vector maps, turn-by-turn routing, search, and preloading | MapLibre GL, Nominatim, OSRM, `geolocator`, `geocoding` |
| **3D Gaming** | WebGL 3D open-world game server integration & Luanti engine | Flutter `webview_flutter`, Node.js game server |
| **Real-time Messaging** | Direct & group chats, voice messages, image uploads, reply threads | `socket_io_client`, Express, `emoji_picker_flutter` |
| **Smart Camera** | Live camera preview, color filters, face detection overlay, zoom/exposure gestures | `camera`, `google_mlkit_face_detection`, Node.js camera backend |
| **Immersive Gallery** | 360° Dome View, River of Time, monthly timeline, and full-screen viewer | `sensors_plus`, `gal`, `share_plus` |
| **Security & Auth** | Supabase authentication, Google Sign-In, and TOTP 2FA with QR generator | `supabase_flutter`, `google_sign_in`, `qr_flutter` |
| **Design System** | Glassmorphism UI, Particle backgrounds, Gyro Parallax, and Quantum Arc Radial Menu | `glassmorphism_ui`, `flutter_animate`, `lucide_icons_flutter` |

---

## 🏗️ Architecture

```
                                Flutter Client
                                      │
                                      ▼
                          Unified Gateway (Port 10000)
                                      │
       ┌──────────────┬───────────────┼───────────────┬───────────────┬──────────────┐
       │              │               │               │               │              │
       ▼              ▼               ▼               ▼               ▼              ▼
  /aria/*        /api/*          /map/*          /game/*        /camera/*      /settings/*
 ARIA Engine    Search API      Map Engine     Game Server    Camera Server   Settings API
(Port 3003)    (Port 3004)     (Port 3006)     (Port 3005)     (Port 3007)    (Port 3008)
```

---

## 📂 Project Structure

```
Nexal_App/
├── lib/
│   ├── main.dart                  # App entry point & multi-provider configuration
│   ├── config/                    # Global app configuration & API URLs
│   ├── models/                    # Data models (User, Post)
│   ├── providers/                 # State management (Auth, Feed, User, Notifications, Background)
│   ├── services/                  # Network, Socket.IO, Supabase & ARIA service clients
│   ├── theme/                     # App tokens, dark theme, and styling
│   ├── screens/                   # App screens (Social, ARIA AI, Map, Game, Camera, Gallery, Settings)
│   └── widgets/                   # Reusable UI widgets (Quantum Arc Menu, Glass Cards, Particles)
│
├── Backend/
│   ├── src/
│   │   └── gateway.ts             # Gateway reverse proxy & child process manager (Port 10000)
│   ├── aria_backend/              # ARIA AI voice backend (Port 3003)
│   ├── search_backend/            # Search & feed REST API (Port 3004)
│   ├── game_backend/              # WebGL static game server (Port 3005)
│   ├── Map_Backend/               # OpenStreetMap tile proxy, Nominatim & OSRM (Port 3006)
│   ├── camera_backend/            # Camera uploads & asset storage API (Port 3007)
│   └── Setting Backend/           # User settings sync backend (Port 3008)
│
├── android/                       # Android native configuration
├── ios/                           # iOS native configuration
└── assets/                        # Icons, maps, static graphics, and audio assets
```

---

## 🛠️ Getting Started

### Prerequisites

- **Flutter SDK**: `>=3.10.7`
- **Node.js**: `>=20.x` and `npm >=10.x`
- **Device**: Physical Android or iOS device recommended for Camera, GPS, Gyroscope, and Microphone features.

### 1. Mobile App Setup

```bash
git clone https://github.com/aaweshdas/The-New-Era-_-Nexal-APP-.git
cd The-New-Era-_-Nexal-APP-
flutter pub get
flutter run
```

### 2. Backend Services Setup

```bash
cd Backend
npm install
cp aria_backend/.env.example aria_backend/.env
# Configure your API keys in aria_backend/.env
npm run dev
```

---

## 🔐 Environment Variables

Create `Backend/aria_backend/.env`:

```env
GROQ_API_KEY=your_groq_api_key
DEEPGRAM_API_KEY=your_deepgram_api_key
PORT=3003
```

- **Groq API Key**: Obtain for free at [console.groq.com](https://console.groq.com)
- **Deepgram API Key**: Obtain for free at [console.deepgram.com](https://console.deepgram.com)

---

## 🌐 Platform Support

| Platform | Status | Features / Notes |
|---|---|---|
| Android | ✅ Supported | Full feature support (Camera, ML Kit, GPS, Sensors, Microservices) |
| iOS | ✅ Supported | Full support (requires iOS permissions in `Info.plist`) |
| Web | ⚠️ Partial | WebGL game & maps work; microphone requires HTTPS context |
| Desktop | ⚠️ Partial | Navigation & backend work; hardware camera capabilities limited |

---

## 🧰 Tech Stack

* **Frontend**: Flutter, Dart, Material 3, Glassmorphism UI
* **State Management**: Provider
* **Backend**: Node.js, TypeScript, Express, Socket.IO, `http-proxy` Gateway
* **AI & Voice**: Groq API (LLM), Deepgram API (STT & TTS), WebSockets
* **Maps & Navigation**: MapLibre GL, Nominatim (Geocoding), OSRM (Routing)
* **Camera & ML**: `camera`, Google ML Kit Face Detection
* **Database & Auth**: Supabase, Google Sign-In, TOTP 2FA

---

## 👤 Author

**Aawesh Das** — [@aaweshdas](https://github.com/aaweshdas)

---

<p align="center"><sub>Built with Flutter & Node.js · 2026</sub></p>
