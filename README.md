<p align="center">
  <img src="assets/nexal_logo.png" width="120" alt="Nexal Logo" />
</p>

<h1 align="center">Nexal</h1>

<p align="center">
  <strong>One app. Everything you need.</strong><br/>
  <sub>A unified super app — social, AI, maps, gaming, and messaging in a single install.</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=flat-square&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.10+-0175C2?style=flat-square&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Node.js-20+-339933?style=flat-square&logo=node.js&logoColor=white" />
  <img src="https://img.shields.io/badge/TypeScript-5.4+-3178C6?style=flat-square&logo=typescript&logoColor=white" />
  <img src="https://img.shields.io/badge/License-MIT-EC4899?style=flat-square" />
</p>

---

## Overview

Nexal is a Flutter-based super app that consolidates five separate applications — social feed, AI assistant, navigation, 3D gaming, and real-time messaging — into a single lightweight install. The motivation is simple: users should not need to download and maintain multiple heavy apps when everything can be in one place.

The backend is a unified Node.js gateway that routes requests to four independent microservices, all accessible through a single public port.

---

## Features

| Module | Description |
|---|---|
| **Social Feed** | Posts, short video reels, stories, bookmarks, and follow system |
| **ARIA AI Assistant** | Voice-to-voice AI using Deepgram STT + Groq LLM + Deepgram TTS |
| **Navigation** | Self-hosted MapLibre GL maps with turn-by-turn routing (no API cost) |
| **3D Game** | Embedded WebGL open-world game rendered via Flutter WebView |
| **Messaging** | Real-time Socket.IO chat with image attachments and reply threads |
| **Camera** | Live preview with color filters, face detection, flash, and zoom |
| **Gallery** | 360° dome view, timeline browser, full-screen viewer with sharing |
| **Security** | TOTP-based 2FA setup with QR code generation and verification |

---

## Architecture

```
Flutter Client
      │
      ▼
Gateway  (Port 10000)
      │
      ├── /api/*   →  Search API        (Port 3004)
      ├── /map/*   →  Map Engine        (Port 3006)
      ├── /game/*  →  Game File Server  (Port 3005)
      └── /*       →  ARIA AI Engine    (Port 3003)
```

---

## Project Structure

```
Nexal_App/
├── lib/
│   ├── main.dart
│   ├── theme/            # Design tokens, colors, and typography
│   ├── models/           # Data models
│   ├── providers/        # State management (FeedProvider, UserProvider)
│   ├── services/         # HTTP and Socket.IO clients
│   ├── screens/          # All app screens
│   └── widgets/          # Reusable UI components
│
├── android/
│   └── build.gradle.kts  # Gradle build configuration
│
└── Backend/
    ├── src/gateway.ts    # Unified gateway router
    ├── aria_backend/     # Groq + Deepgram AI service
    ├── search_backend/   # Search REST API
    ├── game_backend/     # WebGL static file server
    └── Map_Backend/      # Nominatim + OSRM map proxy
```

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.10.7`
- Node.js `>=20.x` and npm `>=10.x`
- A physical device is recommended for camera, GPS, and microphone features

### Mobile App

```bash
git clone https://github.com/aaweshdas/The-New-Era-_-Nexal-APP-.git
cd The-New-Era-_-Nexal-APP-
flutter pub get
flutter run
```

### Backend

```bash
cd Backend
npm install
cp aria_backend/.env.example aria_backend/.env
# Add your API keys to aria_backend/.env
npm run dev
```

---

## Environment Variables

Create `Backend/aria_backend/.env`:

```env
GROQ_API_KEY=your_groq_api_key
DEEPGRAM_API_KEY=your_deepgram_api_key
PORT=3003
```

- **Groq API Key** — free at [console.groq.com](https://console.groq.com)
- **Deepgram API Key** — free at [console.deepgram.com](https://console.deepgram.com)

---

## Platform Support

| Platform | Status | Notes |
|---|---|---|
| Android | ✅ Supported | All hardware features available |
| iOS | ✅ Supported | Requires `Info.plist` permission entries |
| Web | ⚠️ Partial | Microphone requires HTTPS |
| Desktop | ⚠️ Partial | Camera support is limited |

---

## Tech Stack

**Flutter**
`flutter_animate` · `google_fonts` · `camera` · `geolocator` · `webview_flutter` · `socket_io_client` · `record` · `audioplayers` · `google_mlkit_face_detection` · `share_plus` · `image_gallery_saver`

**Backend**
Node.js · TypeScript · Express · Socket.IO · Groq SDK · Deepgram SDK

---

## Author

**Aawesh Das** — [@aaweshdas](https://github.com/aaweshdas)

---

<p align="center"><sub>Built with Flutter · Node.js · 2026</sub></p>
