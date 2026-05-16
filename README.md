# NEXAL — Comprehensive App Documentation

## Overview

**Nexal** (package name: `nexal`) is a premium Flutter social-media application with a futuristic, space-themed dark UI. It targets Android, iOS, Web, Windows, Linux, and macOS. The app uses a deep-space aesthetic with glassmorphism, gradient-based glows, micro-animations, and a custom gyroscope-driven parallax effect. The brand colors are **purple (#A855F7)**, **pink (#EC4899)**, **cyan (#06B6D4)**, and **blue (#3B82F6)** on a pure-black background. Typography uses **Google Fonts Outfit** for body text and **Google Fonts Rye** for headers/titles (rustic serif style).

**Version:** 1.0.0+1  
**Dart SDK:** ^3.10.7  
**State management:** Provider (included in deps, used lightly)

---

## App Boot Flow

1. **`main.dart`** → runs `NexalApp`, a `MaterialApp` with `AppTheme.darkTheme`.
2. **Initial route:** `SplashVideoScreen` (full-screen cinematic video).
3. After video ends → fades into `HomeScreen` (the galaxy hub).

### Splash Video (`lib/screens/splash_video_screen.dart`)
- Plays `assets/videos/startup.mp4` at **1x speed with audio**.
- Full-screen immersive mode (hides system UI).
- Not skippable — plays to completion every launch.
- On finish → **fade transition** (600ms) into `HomeScreen`.
- Uses `video_player` package with `VideoPlayerController.asset()`.

---

## Architecture & Directory Structure

```
lib/
├── main.dart                           # Entry point, MaterialApp, global RouteObserver
├── theme/
│   └── app_theme.dart                  # Color constants, ThemeData, gradient definitions
├── utils/
│   └── filter_generator.dart           # Camera filter presets (ColorFilter matrix list)
├── screens/
│   ├── splash_video_screen.dart        # Boot video player
│   ├── home_screen.dart                # Galaxy hub with orbital navigation
│   ├── home_view.dart                  # Social feed ("Quantum Feed")
│   ├── feels_view.dart                 # Vertical reels/short video feed
│   ├── profile_view.dart               # User profile with editable fields
│   ├── messages_view.dart              # DM inbox with Primary/Requests tabs
│   ├── chat_screen.dart                # Full chat screen (send, receive, emoji, calls)
│   ├── video_view.dart                 # Long-form video streaming hub
│   ├── camera_view.dart                # Camera capture with filters, modes, effects
│   ├── camera_preview_screen.dart      # Post-capture image preview
│   ├── search_view.dart                # Explore/search with trending + discovery grid
│   ├── ai_assist_view.dart             # "ARIA" AI chatbot assistant
│   ├── gallery_view.dart               # Photo gallery with premium timeline
│   ├── full_screen_image_view.dart     # Full-screen image viewer
│   ├── immersive_dome_gallery_view.dart # Immersive 3D dome gallery
│   └── monthly_timeline_view.dart      # Monthly timeline photo browser
└── widgets/
    ├── background/
    │   ├── video_background.dart        # Looping video background for HomeScreen
    │   └── particle_background.dart     # Animated particle star field
    ├── common/
    │   └── post_card.dart               # Social post card (likes, comments, shares)
    ├── effects/
    │   └── gyro_parallax.dart           # Gyroscope-driven parallax wrapper
    ├── navigation/
    │   └── quantum_arc_menu.dart        # Custom arc/orbit navigation wheel
    ├── notifications/
    │   └── notification_view.dart       # Notification bottom sheet
    ├── settings/
    │   └── settings_modal.dart          # Settings bottom sheet
    └── gallery/
        ├── dome_gallery.dart            # 3D dome gallery widget
        ├── premium_timeline_gallery.dart # Premium timeline gallery layout
        └── river_of_time_gallery.dart   # River-of-time photo stream
```

### Assets

```
assets/
├── gallery/                            # Gallery background images
├── nav_icons/                          # Custom PNG icons for navigation
│   ├── home.png, reel.png, profile.png
│   ├── Camera.png, Message.png, Gallery.png
│   ├── Long Video.png, notification.png, settings.png
├── nexal_logo.png                      # App logo (used for launcher icons)
└── videos/
    ├── Background.mp4                  # Looping background video for HomeScreen
    └── startup.mp4                     # Cinematic boot splash video
```

---

## Screen-by-Screen Feature Documentation

### 1. HomeScreen (`home_screen.dart`) — Galaxy Hub

The main hub that acts as a launcher. It does **NOT** show social content — it's a visual galaxy with orbital navigation.

**Features:**
- **Video Background** — Looping `Background.mp4` with 0.8 opacity via `VideoBackground` widget. Pauses when another screen is pushed (uses `RouteObserver`).
- **Quantum Arc Menu** — A horizontal, spring-physics-powered, elliptical carousel of 9 navigation nodes. Swipe left/right to browse; tap to navigate. Each node shows a custom PNG icon. The centered item has a glowing halo, and the label uses a scramble-reveal text animation (random characters → real label).
- **Navigation destinations:** Home, Reel, Videos, Profile, Camera, Search, Nexal AI, Message, Gallery.
- **Gyro Parallax** — The entire nav menu is wrapped in `GyroParallax` which reads device accelerometer data via `sensors_plus` and applies a subtle transform.
- **Header** — "NEXAL GALAXY" title with animated shimmer gradient (gold → purple → cyan → pink → gold), and subtitle "Select a star to explore".
- **Notification icon** (top-right) — Opens `NotificationView` as a bottom sheet.
- **Settings icon** (bottom-right) — Opens `SettingsModal` as a bottom sheet.

### 2. HomeView (`home_view.dart`) — Quantum Feed

A social media feed screen.

**Features:**
- **Header** — "Quantum Feed" title with animated gradient glow (purple ↔ cyan), subtitle "AI-curated content stream". Back button and header action icons (sparkles, bell).
- **Live Status Bar** — Glassmorphic container showing "LIVE" indicator with pulsing green dot + activity stats ("2.4K active • 847 new posts • 12 trending").
- **Filter Chips** — Horizontal scrollable: "✦ For You", "🔥 Trending", "👥 Following", "🧠 AI Picks", "🌐 Global". Animated selection with gradient highlight.
- **Trending Topics** — Horizontal cards showing hashtags (#QuantumArt, #NeoTech, etc.) with post counts.
- **Post Cards** — Using `PostCard` widget. Each post has: user avatar, name, verified badge, content text, image, like/comment/share/view counts, time ago. Some posts have "AI picked for you" gradient badges with accent left-border.
- **Floating Create Button** — Purple-to-pink gradient circle with pulsing glow animation.

### 3. FeelsView (`feels_view.dart`) — Vertical Reels

A TikTok/Instagram Reels-style vertical-swipe video feed.

**Features:**
- **8 mock reels** with full-screen background images, gradient overlays, and user info.
- **Double-tap to like** with heart animation.
- **Right sidebar actions:** Follow button (+ icon on avatar), Like (toggleable heart), Comment (opens comment sheet), Share (opens share sheet), Bookmark ("Save"), More options.
- **Comment sheet** — Draggable bottom sheet with mock comments, reply buttons, and comment input.
- **Share sheet** — Send to, Copy Link, Repost, Save Video, Share to... icons.
- **More options sheet** — Report, Not Interested, Block User, Download, Copy Link.
- **Sound indicator** — Bottom-left shows current track name with music icon.
- **Progress bar** — Linear progress indicator at bottom.
- **Page indicator** — Vertical dots on right side showing current position.
- **Top bar** — Back button, "Reels" title (Rye font), mute/unmute toggle.
- **Mute toggle** — Toggles volume icon between volume2 and volumeX.

### 4. ProfileView (`profile_view.dart`) — User Profile

Full user profile with editing capabilities.

**Features:**
- **Cover header** — Banner image with gradient overlay.
- **Avatar** — Center-aligned with gradient border (purple → cyan) and glow shadow. Flanked by achievement badges on both sides.
- **Achievement badges (4):** Top Creator (gold award), 30 Day Streak (pink flame), 10K Likes (cyan star), Pioneer (purple rocket). Each is tappable.
- **Stats row:** Energy (2.4K), Connections (12.5K), Influence (8.9K) — each with themed icon and color.
- **Profile info:** Verified badge, username @neuralnexus, "ELITE CREATOR" gradient badge, bio text, location "Digital Metaverse", website link.
- **Action buttons:** "Edit Profile" (gradient), "Share Profile" (outlined), More options (...).
- **Edit Profile sheet** — Bottom sheet with editable fields for Display Name, Bio, Website. Changes persist in widget state.
- **Content tabs (4):** Creations, Saved, Liked, Repost. Each has icon + label, animated selection.
- **Content grid** — 3-column grid of images from picsum.photos. Repost tab shows "Reposted" badge. Each item is tappable → opens detail sheet with Like/Comment/Share buttons.
- **Settings menu** — Edit Profile, Notifications, Privacy, Help & Support, Log Out. Each opens its own sub-sheet.
- **Notifications settings** — Toggle switches for Push, Message Alerts, Like Notifications, Comment Alerts.
- **Privacy settings** — Toggle switches for Private Account, Show Online Status, Show Activity Status, Allow Messages from All.
- **Logout confirmation** — Dialog with Cancel/Log Out buttons.

### 5. MessagesView (`messages_view.dart`) — DM Inbox

Messaging inbox with two tabs.

**Features:**
- **Header** — "Messages" title (Rye font), unread count subtitle, search toggle, settings button.
- **Search bar** — Glassmorphic text field with search/clear icons. Animated slide-in.
- **Online stories row** — Horizontal scrollable showing online contacts as circular avatars with gradient border. First item is "You" with + icon.
- **Tab bar** — "Primary" and "Requests (N)" tabs with gradient indicator.
- **Primary tab** — List of message items, each with: avatar (with online indicator dot), name, last message, time, unread badge (gradient pill), media indicator icon. Swipe-to-dismiss (archive). Tap opens chat.
- **Requests tab** — Connection requests with Accept (gradient) and Decline (outlined) buttons. Accept moves contact to Primary list.
- **Compose FAB** — Bottom-right floating button with gradient + elastic scale animation.

### 6. ChatScreen (`chat_screen.dart`) — Full Chat

Full-featured individual chat screen.

**Features:**
- **App bar** — Back button, avatar with online dot, name, online status, phone call button, video call button, more options (⋮).
- **Message bubbles** — Sent messages have purple-pink gradient; received have dark glass. Grouped by sender. Shows timestamp and double-check (read receipt) icon for sent messages.
- **Long-press on message** — Bottom sheet with Copy (copies to clipboard), Reply, Delete (sent only, destructive red).
- **Emoji picker** — Toggleable 8-column grid of 40 emojis. Inserts emoji into input field.
- **Attachment options** — Bottom sheet with Camera, Gallery, Document, Audio icons (each with distinct color).
- **Send message** — Sends text, clears input, auto-scrolls to bottom. Simulates a reply after 1.5s from a pool of 8 responses.
- **Scroll-to-bottom button** — Appears when scrolled up; gradient circle with chevron icon.
- **Voice/Video Call dialog** — Animated dialog with pulsing avatar ring, "Calling..." text animation, Mute/Speaker toggles, red hang-up button.
- **More options menu** — Mute Notifications, Block User (destructive), Report (destructive).

### 7. VideoView (`video_view.dart`) — Streaming Hub

Long-form video content browser.

**Features:**
- **Header** — "Videos" title, search toggle, cast button (scans for devices).
- **Search bar** — Glassmorphic text field for videos/creators/genres.
- **Hero banner** — Large featured video with 4K/HDR/DOLBY badges, play button with pulsing glow, bookmark toggle, title and metadata.
- **Category chips** — Horizontal scrollable: Trending, Sci-Fi, Documentary, Live, Gaming, Music.
- **Continue Watching section** — Horizontal cards with thumbnail, circular progress ring showing watch percentage, duration badge, title, creator name.
- **Trending Now section** — Ranked horizontal cards with large outlined rank numbers (1, 2, 3), view count, star rating.
- **Recommended section** — Vertical list of glassmorphic cards with thumbnail, title, creator, views, rating, bookmark toggle, play button.
- **Video Detail sheet** — Draggable bottom sheet with: full thumbnail, title, creator, views, rating, Play Now / Save / Share / Download buttons, and progress bar (if partially watched).
- **Bookmark system** — State-tracked set of bookmarked video IDs. Toggleable from multiple locations.

### 8. CameraView (`camera_view.dart`) — Camera Capture

Full camera interface with capture modes and effects.

**Features:**
- **Live camera preview** — Uses `camera` package with high resolution. Pinch-to-zoom (1x–5x).
- **Top bar** — Back button, zoom indicator, flash toggle (on/off), timer toggle (off/3s/10s), grid toggle.
- **Grid overlay** — 3×3 rule-of-thirds grid lines.
- **Timer countdown** — Full-screen number display with glow.
- **Right toolbar** — Glassmorphic vertical panel with: Flip camera, Effects, Music, Text, Gallery picker.
- **Effects sheet** — 6 effects: Cyber Glitch, Neon Bloom, Matrix Rain, Retrowave, Hologram, Film Grain.
- **Music sheet** — 4 tracks to add as audio overlay.
- **Filter wheel** — Left-side `ListWheelScrollView` showing camera filter previews. Uses `FilterGenerator` utility which provides `ColorFilter` matrices.
- **Shutter button** — Pulsing animation, color matches selected mode.
- **Mode selector** — Bottom row: REEL (pink), STORY (cyan), SPOTLIGHT (yellow), PHOTO (purple). Each has its own accent color.
- **Post-capture** — Navigates to `CameraPreviewScreen` with selected filter applied.
- **Gallery picker** — Opens device gallery via `image_picker`.
- **Lifecycle handling** — Disposes/reinitializes camera on app pause/resume.

### 9. SearchView (`search_view.dart`) — Explore

Discovery and trending content browser.

**Features:**
- **Custom nebula background** — Animated `CustomPaint` with purple and pink radial gradients and 60 twinkling stars.
- **Header** — Glass icon button, "EXPLORE" label (Rye font), avatar with notification dot.
- **Search bar** — Pulsing glow animation, search icon, mic icon, AI sparkle icon. Uses `Space Grotesk` font for search-specific text.
- **ARIA Suggests** — AI suggestion panel with brain icon and 4 suggestion chips (Quantum Physics, Neural Art, Space Exploration, Bio-Hacking).
- **Filter tabs** — ALL, PEOPLE, PHOTOS, VIDEOS, PLACES, LIVE. Gradient highlight on active tab.
- **Trending Now section** — 5 ranked trending items with: rank number, topic name, category, post count (formatted as K). Uses color-coded rank circles (gold → gradient).
- **Neural Discovery section** — Masonry-style 2-column grid of discovery cards. Each card has: gradient background, hashtag, title, author handle. Cards have variable heights for visual interest.

### 10. AIAssistView (`ai_assist_view.dart`) — NEXAL AI (ARIA)

AI chatbot companion with rich visual design.

**Features:**
- **Star field background** — 24 randomly positioned, animated twinkling stars.
- **Nebula glows** — Ambient purple and pink radial glows.
- **Top bar** — Close (X) button, "NEXAL AI" title with "Neural Companion v2.0" subtitle, History button.
- **Neural Orb** — Central animated orb with 7 visual layers:
  1. Ambient breathing halo (pulsing scale)
  2. Quantum core (spirograph `CustomPaint`, slow rotation)
  3. Dashed HUD ring (counter-rotating)
  4. Outer photon data stream (rotating custom paint)
  5. Two 3D orbital rings (perspective-transformed, opposite rotations)
  6. Orbital particles (two small dots orbiting at different speeds)
  7. Core glass element — radial gradient with "ARIA" label
- **Status indicator** — "Active • Neural Mode" with blinking cyan dot.
- **Waveform section** — 14-bar animated waveform (sin wave), "Listening to your thoughts..." subtitle.
- **Quick command chips** — Write, Analyse, Create, Summarize, Translate. Tapping inserts text into input.
- **Chat area** — Glassmorphic container with message bubbles:
  - User messages: right-aligned, dark purple surface
  - ARIA messages: left-aligned, with small gradient orb avatar "A"
  - Each has timestamp and copy button
- **Typing indicator** — Three pulsing dots with ARIA avatar.
- **Simulated AI responses** — Sends a generic response after 2s delay.
- **Input bar** — Microphone button (hold to listen), text field, send button with gradient glow.
- **Bottom nav** — Chat/Canvas/Live mode selector.

### 11. GalleryView (`gallery_view.dart`) — Photo Gallery

Photo gallery with premium timeline layout.

**Features:**
- **Background image** — `gallery_background.jpg` with dark overlay.
- **Premium Timeline Gallery** — Embedded `PremiumTimelineGallery` widget showing photos in a chronological timeline layout.
- **Floating pill header** — Glassmorphic blur pill with: back button, home button, "TIMELINE" badge, "NEXAL" logo (Rye font), search toggle, settings menu.
- **Search overlay** — Full-screen overlay with search field, recent searches (2024, Quantum Launch, Neon Synchrony).
- **Settings sheet** — Change Timeline Layout, Sort Order, Filter by Category, Cloud Sync, Gallery Preferences.

---

## Shared Widgets Documentation

### VideoBackground (`widgets/background/video_background.dart`)
- Loops `assets/videos/Background.mp4` with configurable opacity.
- Can be paused/resumed via `isPaused` property (used by RouteObserver).

### ParticleBackground (`widgets/background/particle_background.dart`)
- Animated canvas of floating particles/stars for ambient backgrounds.

### GyroParallax (`widgets/effects/gyro_parallax.dart`)
- Wraps a child widget and applies translation based on device accelerometer.
- `intensity` parameter controls effect magnitude.
- Uses `sensors_plus` package.

### QuantumArcMenu (`widgets/navigation/quantum_arc_menu.dart`)
- Custom elliptical arc navigation with spring-physics scrolling.
- 9 navigation items arranged on an elliptical path.
- Features: depth-based scaling, opacity, centered item glow with pulsing animation, scramble-reveal text label.
- Uses `SpringSimulation` for snap-back on release.
- Items with custom PNG icons: home, reel, video, profile, camera, message, gallery. Others use Lucide icons.

### PostCard (`widgets/common/post_card.dart`)
- Reusable social media post card.
- Displays: user avatar, name, verified badge, content text, image, like/comment/share counts, view count, time ago.

### NotificationView (`widgets/notifications/notification_view.dart`)
- Bottom sheet with grouped notifications (Today / Yesterday).
- Each notification has: icon (color-coded), title, content, time, unread dot indicator.
- Categories: messages, system updates, security alerts, likes.

### SettingsModal (`widgets/settings/settings_modal.dart`)
- Full-height bottom sheet (90% screen) with backdrop blur.
- Categories: Account (Edit Profile, Privacy & Security), Preferences (Notifications toggle, Dark Mode toggle, Language), About (Help & Support, About Nexal v1.0.0).

### Gallery Widgets (`widgets/gallery/`)
- **DomeGallery** — Immersive 3D dome-style photo viewer.
- **PremiumTimelineGallery** — Chronological photo timeline with year markers.
- **RiverOfTimeGallery** — Flowing stream-style photo browser.

---

## Theme System (`lib/theme/app_theme.dart`)

```dart
purple500 = Color(0xFFA855F7)   // Primary accent
pink500   = Color(0xFFEC4899)   // Secondary accent
blue500   = Color(0xFF3B82F6)   // Tertiary
cyan500   = Color(0xFF06B6D4)   // Highlight / active states
background = Color(0xFF000000)  // Pure black
```

- `darkTheme` — `ThemeData.dark()` with Outfit text theme, black scaffold, purple primary.
- `deepSpaceGradient` — Multi-stop gradient from black through dark blue-black hints.

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_animate` | ^4.5.2 | Declarative animations (fadeIn, slideX, scale, etc.) |
| `google_fonts` | ^8.0.0 | Outfit (body), Rye (headers), Space Grotesk (AI), Manrope (search) |
| `lucide_icons` | ^0.257.0 | Icon set used throughout the app |
| `provider` | ^6.1.5+1 | State management (available but lightly used) |
| `glassmorphism_ui` | ^0.3.0 | Glassmorphic container widgets |
| `sensors_plus` | ^7.0.0 | Accelerometer data for gyro parallax |
| `flutter_staggered_grid_view` | ^0.7.0 | Staggered/masonry grid layouts |
| `video_player` | ^2.11.0 | Video playback (splash, backgrounds) |
| `camera` | ^0.12.0 | Camera capture |
| `permission_handler` | ^12.0.1 | Runtime permission requests |
| `image_picker` | ^1.2.1 | Gallery image selection |
| `flutter_launcher_icons` | ^0.14.3 | Generate launcher icons from `nexal_logo.png` |

---

## Launcher Icons

Configured via `flutter_launcher_icons` in `pubspec.yaml`:
- **Source image:** `assets/nexal_logo.png`
- **Android:** Adaptive icons with black background (#000000) and logo foreground
- **iOS:** Standard icon with alpha removed
- **Web, Windows:** Generated from same source

---

## Design Language Summary

| Element | Approach |
|---------|----------|
| **Background** | Pure black (#000000) with subtle gradient hints |
| **Cards/Containers** | Glassmorphic — semi-transparent with blur, thin borders |
| **Accents** | Gradient purple→pink for primary actions, cyan for active/online states |
| **Animations** | flutter_animate for entrances; AnimationController for continuous effects (pulse, glow, rotation) |
| **Typography** | Rye for titles/headers, Outfit for body/UI, Space Grotesk for AI/tech contexts |
| **Navigation** | Spring-physics orbital arc menu on HomeScreen; standard push navigation elsewhere |
| **Bottom sheets** | Consistent style — dark (#0d0d1a), rounded top (28px), drag handle, Rye-font titles |
| **Buttons** | Gradient-filled for primary actions, outlined/transparent for secondary |
| **Status indicators** | Pulsing green dot for online, gradient badges for unread counts |

---

## Important Implementation Notes

1. **All data is mock/hardcoded** — No backend, no database, no API calls. User avatars and content images come from Unsplash and Picsum URLs.
2. **No authentication system** — Login/signup flows do not exist.
3. **No persistent storage** — All state resets on app restart (messages, profile edits, likes, follows, etc.).
4. **The AI assistant (ARIA) returns canned responses** — Not connected to any LLM API.
5. **Camera functionality is real** — Uses device camera with real capture, flash, zoom, timer, and filter application.
6. **The splash video plays every launch** — Not skip-able, not conditional on first-run.
7. **Network images may fail** — All network images have `errorBuilder` fallbacks rendering placeholder containers.
8. **RouteObserver pattern** — Used to pause/resume the HomeScreen video background when navigating to/from sub-screens.
9. **Multiple font families** — Rye, Outfit, Space Grotesk, and Manrope are all used in different contexts.
10. **Custom painters** — Used extensively for: arc track, grid overlay, nebula background, quantum core spirograph, dashed rings, data streams, orbital rings.
