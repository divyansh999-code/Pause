# Pause ⏸

> An Android app that makes you think before you scroll.

Pause intercepts any app you choose — Instagram, WhatsApp, YouTube — and asks you one question before you get in:

**"Why do you want to open this app right now?"**

You write your reason. Then you decide:
- **I'll skip it** — close and move on
- **Open anyway** — conscious choice, you're in

No blocking. No timers. No streaks. Just friction.

---

## Demo

https://github.com/user-attachments/assets/YOUR_VIDEO_ID

---

## Screenshots

| Home Screen | Mindful Pause | Insights |
|---|---|---|
| ![Home](screenshots/home.jpg) | ![Overlay](screenshots/overlay.jpg) | ![Insights](screenshots/insights.jpg) |

---

## How It Works

1. User opens a monitored app (e.g. Instagram)
2. Native Kotlin Accessibility Service detects the app launch
3. A full-screen Flutter overlay appears immediately
4. User must write a reflection before proceeding
5. User chooses to skip or proceed — both decisions are logged
6. Insights screen tracks reflection history over time

---

## Tech Stack

- **Flutter** — UI, overlay screen, insights
- **Kotlin** — Native Android Accessibility Service
- **flutter_overlay_window** — System overlay rendering
- **SharedPreferences** — Local data persistence
- **installed_apps** — App picker with real icons
- **Riverpod** — State management

---

## Architecture

```
lib/
├── main.dart                   # App entry point + overlay entry point
├── services/
│   ├── accessibility_service.dart   # MethodChannel bridge to native
│   └── storage_service.dart         # Local persistence
├── screens/
│   ├── home_screen.dart             # Dashboard + app management
│   ├── insights_screen.dart         # Reflection history + stats
│   └── overlay/
│       └── pause_overlay.dart       # The reflection UI
└── models/
    └── pause_models.dart            # Data models

android/app/src/main/kotlin/com/antigravity/pause/
├── MainActivity.kt                  # MethodChannel setup
└── PauseAccessibilityService.kt     # Native app launch detection
```

---

## Installation

### Download APK
[Download latest APK](https://drive.google.com/YOUR_LINK_HERE)

### Build from source
```bash
git clone https://github.com/YOUR_USERNAME/pause.git
cd pause
flutter pub get
flutter build apk --release
```

**Requirements:**
- Flutter 3.x
- Android SDK (API 26+)
- Android device (emulator won't work — accessibility service requires real device)

---

## Setup on Device

1. Install APK
2. Open Pause
3. Tap **Mindfulness Service** toggle → enable in Android Accessibility Settings
4. Tap **+** to add apps you want to monitor
5. Open any monitored app — Pause will intercept it

---



## Made by

**Divyansh Khandal**  
2nd Year BE — AI & Data Science, M.B.M. Engineering College, Jodhpur  
[LinkedIn](https://linkedin.com/in/divyansh-khandal-5b8b8b32b) · [GitHub](https://github.com/divyansh999-code)

---

*Built in 2 days. Works on my phone daily.*
